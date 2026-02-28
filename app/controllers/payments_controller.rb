class PaymentsController < ApplicationController
  before_action :require_login!
  before_action :set_booking
  before_action :require_owner!

  def new
    if @booking.payment&.success? || @booking.confirmed? || @booking.completed?
      return redirect_to booking_path(@booking), alert: "이미 결제가 완료된 예약입니다."
    end
    unless @booking.awaiting_payment?
      return redirect_to booking_path(@booking), alert: "호스트 예약확정 후 결제를 진행할 수 있습니다."
    end

    @payment = @booking.payment || @booking.build_payment(user: current_user, amount: @booking.total_price, currency: @booking.currency)
  end

  def create
    if @booking.payment&.success? || @booking.confirmed? || @booking.completed?
      return redirect_to booking_path(@booking), alert: "이미 결제가 완료된 예약입니다."
    end
    unless @booking.awaiting_payment?
      return redirect_to booking_path(@booking), alert: "호스트 예약확정 후 결제를 진행할 수 있습니다."
    end

    @payment = @booking.payment || @booking.build_payment(user: current_user)
    @payment.assign_attributes(payment_params.merge(amount: @booking.total_price, currency: @booking.currency, user: current_user))
    @payment.payment_status = :success
    @payment.pg_transaction_id = "PG#{SecureRandom.hex(8)}"
    @payment.pg_provider ||= provider_from_method(@payment.payment_method)
    @payment.paid_at = Time.current

    ActiveRecord::Base.transaction do
      @payment.save!
      @booking.update!(status: :confirmed)
      @booking.coupon&.increment!(:used_count) if @booking.coupon.present?
    end

    redirect_to booking_path(@booking), notice: "결제가 완료되어 예약이 확정되었습니다."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = @payment.errors.full_messages.to_sentence.presence || "결제 처리에 실패했습니다."
    render :new, status: :unprocessable_entity
  end

  private

  def set_booking
    @booking = Booking.includes(:payment, :coupon, room_type: :property).find(params[:booking_id] || params[:id])
  end

  def require_owner!
    return if @booking.user_id == current_user.id || current_user.admin?

    redirect_to root_path, alert: "결제 권한이 없습니다."
  end

  def payment_params
    params.require(:payment).permit(:payment_method)
  end

  def provider_from_method(method)
    { "card" => "mock_card_pg", "kakao" => "kakao_pay", "naver" => "naver_pay", "toss" => "toss_pay" }.fetch(method.to_s, "mock_pg")
  end
end
