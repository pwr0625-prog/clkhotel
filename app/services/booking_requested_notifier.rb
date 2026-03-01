class BookingRequestedNotifier
  TEMPLATE_CODE = "BOOKING_REQUESTED_HOST".freeze

  def self.call(...)
    new.call(...)
  end

  def call(booking)
    host = booking.property.host
    guest = booking.user
    property = booking.property

    message = <<~TEXT.strip
      [ClkHotel] 새로운 예약 요청이 접수되었습니다.
      숙소: #{property.property_name}
      예약번호: #{booking.booking_code}
      일정: #{booking.check_in_date} ~ #{booking.check_out_date} (#{booking.nights}박)
      인원/객실: #{booking.guest_count}명 / #{booking.room_count}실
      게스트: #{guest.name}
    TEXT

    KakaoMessageService.call(
      phone: host.phone,
      template_code: TEMPLATE_CODE,
      variables: {
        host_name: host.name,
        guest_name: guest.name,
        property_name: property.property_name,
        booking_code: booking.booking_code,
        check_in_date: booking.check_in_date.to_s,
        check_out_date: booking.check_out_date.to_s,
        nights: booking.nights,
        guest_count: booking.guest_count,
        room_count: booking.room_count
      },
      fallback_text: message
    )
  end
end
