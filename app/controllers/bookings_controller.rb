class BookingsController < ApplicationController
  before_action :require_login!
  before_action :set_booking, only: %i[show cancel complete]
  before_action :authorize_booking_access!, only: %i[show]
  before_action :authorize_booking_owner!, only: %i[cancel complete]

  def my
    @bookings = current_user.bookings.includes({ room_type: :property }, :payment, :review).order(created_at: :desc)
  end

  def create
    require_guest!
    return if performed?

    room_type = RoomType.includes(:property).find(booking_params[:room_type_id])
    if room_type.property.closed_for_guest?
      redirect_to properties_path, alert: "현재 준비중인 숙소는 예약할 수 없습니다."
      return
    end

    @booking = room_type.bookings.build(booking_params.except(:room_type_id, :coupon_code))
    @booking.user = current_user
    @booking.coupon = Coupon.find_by(coupon_code: booking_params[:coupon_code].to_s.strip.upcase) if booking_params[:coupon_code].present?

    begin
      ActiveRecord::Base.transaction do
        @booking.save!
        ::RoomInventoryService.reserve!(@booking)
      end

      begin
        result = BookingRequestedNotifier.call(@booking)
        unless result.success?
          Rails.logger.warn("[BookingRequestedNotifier] failed: #{result.message}")
        end
      rescue StandardError => e
        Rails.logger.error("[BookingRequestedNotifier] #{e.class}: #{e.message}")
      end

      redirect_to booking_path(@booking), notice: "예약 요청이 접수되었습니다. 호스트 예약확정 후 결제를 진행할 수 있습니다."
    rescue ActiveRecord::RecordInvalid
      @property = room_type.property
      @wishlist = current_user.wishlists.find_by(property: @property)
      render "properties/show", status: :unprocessable_entity
    rescue ::RoomInventoryService::Error => e
      @booking.errors.add(:base, e.message)
      @property = room_type.property
      @wishlist = current_user.wishlists.find_by(property: @property)
      render "properties/show", status: :unprocessable_entity
    end
  end

  def show; end

  def cancel
    if @booking.cancelled? || @booking.completed?
      redirect_to booking_path(@booking), alert: "이미 처리된 예약입니다."
      return
    end

    unless @booking.awaiting_payment? || @booking.confirmed?
      redirect_to booking_path(@booking), alert: "호스트 예약확정 후 결제/취소 단계에서만 취소할 수 있습니다."
      return
    end

    ActiveRecord::Base.transaction do
      ::RoomInventoryService.release!(@booking) if @booking.inventory_holding?
      @booking.update!(status: :cancelled, cancelled_at: Time.current)

      if @booking.payment&.success?
        @booking.payment.update!(payment_status: :refunded, refund_amount: @booking.payment.amount, refunded_at: Time.current)
      end
    end

    redirect_to booking_path(@booking), notice: "예약을 취소했습니다."
  end

  def complete
    @booking.update!(status: :completed)
    redirect_to booking_path(@booking), notice: "숙박 완료 처리되었습니다. 리뷰를 작성할 수 있습니다."
  end

  private

  def set_booking
    @booking = Booking.includes(:user, :coupon, :payment, :review, room_type: :property).find(params[:id])
  end

  def authorize_booking_access!
    return if @booking.user_id == current_user.id
    return if current_user.host? && @booking.property.host_id == current_user.id
    return if current_user.admin?

    redirect_to root_path, alert: "예약 조회 권한이 없습니다."
  end

  def authorize_booking_owner!
    unless @booking.user_id == current_user.id || current_user.admin?
      redirect_to root_path, alert: "예약 처리 권한이 없습니다."
    end
  end

  def booking_params
    params.require(:booking).permit(:room_type_id, :check_in_date, :check_out_date, :guest_count, :room_count, :guest_requests, :coupon_code)
  end
end
