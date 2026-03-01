require "test_helper"

class BookingHostNotificationTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []

  def create_user!(name:, email:, user_type:, phone:)
    User.create!(
      name: name,
      email: email,
      phone: phone,
      user_type: user_type,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_property_with_room!(host:)
    property = Property.create!(
      host: host,
      property_name: "알림 테스트 호텔",
      city: "서울",
      address: "서울시 강남구 101",
      is_open: true
    )

    room_type = property.room_types.create!(
      room_name: "스탠다드",
      base_price: 100_000,
      max_guests: 2,
      total_count: 2,
      currency: "KRW"
    )

    [property, room_type]
  end

  test "booking request triggers host notification" do
    host = create_user!(name: "Host", email: "host-noti-#{SecureRandom.hex(3)}@example.com", user_type: :host, phone: "010-1111-2222")
    guest = create_user!(name: "Guest", email: "guest-noti-#{SecureRandom.hex(3)}@example.com", user_type: :guest, phone: "010-3333-4444")
    _property, room_type = create_property_with_room!(host: host)

    post login_url, params: { email: guest.email, password: "password123" }
    assert_redirected_to root_url

    called_booking_id = nil
    fake_result = Struct.new(:success?, :message).new(true, "ok")

    original_call = BookingRequestedNotifier.method(:call)
    BookingRequestedNotifier.define_singleton_method(:call) do |booking|
      called_booking_id = booking.id
      fake_result
    end

    begin
      assert_difference("Booking.count", 1) do
        post bookings_url, params: {
          booking: {
            room_type_id: room_type.id,
            check_in_date: Date.current + 7,
            check_out_date: Date.current + 8,
            guest_count: 1,
            room_count: 1
          }
        }
      end
    ensure
      BookingRequestedNotifier.define_singleton_method(:call) { |*args, **kwargs| original_call.call(*args, **kwargs) }
    end

    booking = Booking.order(:created_at).last
    assert_equal booking.id, called_booking_id
    assert_redirected_to booking_url(booking)
  end

  test "booking is created even when host notification raises error" do
    host = create_user!(name: "Host", email: "host-noti-fail-#{SecureRandom.hex(3)}@example.com", user_type: :host, phone: "010-1111-2222")
    guest = create_user!(name: "Guest", email: "guest-noti-fail-#{SecureRandom.hex(3)}@example.com", user_type: :guest, phone: "010-3333-4444")
    _property, room_type = create_property_with_room!(host: host)

    post login_url, params: { email: guest.email, password: "password123" }
    assert_redirected_to root_url

    original_call = BookingRequestedNotifier.method(:call)
    BookingRequestedNotifier.define_singleton_method(:call) do |_booking|
      raise "kakao temporary failure"
    end

    begin
      assert_difference("Booking.count", 1) do
        post bookings_url, params: {
          booking: {
            room_type_id: room_type.id,
            check_in_date: Date.current + 7,
            check_out_date: Date.current + 8,
            guest_count: 1,
            room_count: 1
          }
        }
      end
    ensure
      BookingRequestedNotifier.define_singleton_method(:call) { |*args, **kwargs| original_call.call(*args, **kwargs) }
    end

    booking = Booking.order(:created_at).last
    assert_redirected_to booking_url(booking)
    follow_redirect!
    assert_match "예약 요청이 접수되었습니다.", response.body
  end
end
