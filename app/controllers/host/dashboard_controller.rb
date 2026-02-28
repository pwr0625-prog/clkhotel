module Host
  class DashboardController < ApplicationController
    before_action :require_host!

    def index
      @properties = current_user.properties.includes(:room_types, :reviews).order(created_at: :desc)
      @recent_bookings = host_bookings.limit(10)
    end

    def bookings
      @bookings = host_bookings
    end

    def confirm_form
      @booking = host_scoped_booking
      unless @booking.pending?
        return redirect_to host_bookings_path, alert: "예약확정 대기 상태에서만 호수 지정 후 확정할 수 있습니다."
      end

      @available_room_numbers = @booking.room_type.available_room_numbers_for(@booking)
    end

    def confirm
      booking = host_scoped_booking
      unless booking.pending?
        return redirect_to host_bookings_path, alert: "예약확정 대기 상태에서만 확정할 수 있습니다."
      end
      if booking.room_type.room_numbers.blank?
        return redirect_to host_room_type_inventory_path(booking.room_type), alert: "먼저 객실 재고관리에서 호수 번호를 등록해 주세요."
      end

      booking.assign_attributes(
        assigned_room_numbers: params.dig(:booking, :assigned_room_numbers),
        status: :awaiting_payment
      )

      if booking.room_type.room_numbers.present? && booking.assigned_room_numbers.size != booking.room_count
        return redirect_to host_confirm_booking_form_path(booking),
                           alert: "예약 객실 수(#{booking.room_count})만큼 호수를 선택해 주세요."
      end

      booking.save!

      result = BookingConfirmedNotifier.call(booking)
      notice = if result.success?
        "예약을 확정했습니다. 게스트가 결제/취소를 진행할 수 있습니다. 카카오 메시지(#{result.mode})를 발송했습니다."
      else
        "예약을 확정했습니다. 게스트가 결제/취소를 진행할 수 있습니다. 카카오 메시지 발송 실패: #{result.message}"
      end

      redirect_to host_bookings_path, notice: notice
    rescue ActiveRecord::RecordInvalid => e
      redirect_to host_confirm_booking_form_path(booking), alert: e.record.errors.full_messages.to_sentence
    end

    def reject
      booking = host_scoped_booking
      ActiveRecord::Base.transaction do
        ::RoomInventoryService.release!(booking) if booking.inventory_holding?
        booking.update!(status: :cancelled, cancelled_at: Time.current)
      end
      redirect_to host_bookings_path, notice: "예약을 거절했습니다."
    end

    def destroy
      booking = host_scoped_booking
      ActiveRecord::Base.transaction do
        ::RoomInventoryService.release!(booking) if booking.inventory_holding?
        booking.destroy!
      end
      redirect_to host_bookings_path, notice: "예약을 삭제했습니다."
    end

    private

    def host_bookings
      Booking.includes(:user, :payment, room_type: :property)
             .joins(room_type: :property)
             .where(properties: { host_id: current_user.id })
             .order(created_at: :desc)
    end

    def host_scoped_booking
      host_bookings.find(params[:id])
    end
  end
end
