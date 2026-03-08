require "test_helper"

class HostRoomInventoryCalendarTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []

  def create_user!(name:, email:, user_type:)
    User.create!(
      name: name,
      email: email,
      user_type: user_type,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_property_with_room!(host:)
    property = Property.create!(
      host: host,
      property_name: "달력 테스트 호텔",
      city: "서울",
      address: "서울시 중구 2"
    )

    room_type = property.room_types.create!(
      room_name: "디럭스",
      base_price: 120_000,
      max_guests: 2,
      total_count: 3,
      room_numbers_text: "301, 302, 303",
      currency: "KRW"
    )

    property.room_types.create!(
      room_name: "스탠다드",
      base_price: 90_000,
      max_guests: 2,
      total_count: 2,
      currency: "KRW"
    )

    [property, room_type]
  end

  test "host can view inventory and booking status in calendar" do
    host = create_user!(name: "Host One", email: "host-cal-#{SecureRandom.hex(3)}@example.com", user_type: :host)
    guest = create_user!(name: "Guest One", email: "guest-cal-#{SecureRandom.hex(3)}@example.com", user_type: :guest)
    property, room_type = create_property_with_room!(host: host)

    check_in = Date.current + 8.days
    check_out = check_in + 2.days
    booking = Booking.create!(
      user: guest,
      room_type: room_type,
      check_in_date: check_in,
      check_out_date: check_out,
      guest_count: 2,
      room_count: 1,
      status: :confirmed,
      assigned_room_numbers_text: "301"
    )
    RoomInventoryService.reserve!(booking)

    post login_url, params: { email: host.email, password: "password123" }
    assert_redirected_to root_url

    get host_property_inventory_url(
      property,
      from: check_in,
      to: check_out,
      month: check_in.strftime("%Y-%m"),
      selected_date: check_in
    )

    assert_response :success
    assert_match "재고/예약 달력", response.body
    assert_match "총 잔여", response.body
    assert_match "디럭스 / 301", response.body
    assert_match booking.booking_code, response.body
    assert_match guest.name, response.body
    assert_select ".inventory-timeline__bar", 1
    assert_select ".inventory-calendar__day--selected", 1
  end
end
