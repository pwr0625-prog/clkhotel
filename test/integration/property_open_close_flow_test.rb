require "test_helper"

class PropertyOpenCloseFlowTest < ActionDispatch::IntegrationTest
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

  def create_property_with_room!(host:, is_open:)
    property = Property.create!(
      host: host,
      property_name: "준비중 테스트 호텔",
      city: "서울",
      address: "서울시 강남구 10",
      is_open: is_open
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

  test "guest cannot access closed property detail" do
    host = create_user!(name: "Host One", email: "host-one-#{SecureRandom.hex(3)}@example.com", user_type: :host)
    property, = create_property_with_room!(host: host, is_open: false)

    get property_url(property)

    assert_redirected_to properties_url
    follow_redirect!
    assert_match "현재 준비중인 숙소입니다.", response.body
  end

  test "guest cannot create booking for closed property" do
    host = create_user!(name: "Host Two", email: "host-two-#{SecureRandom.hex(3)}@example.com", user_type: :host)
    guest = create_user!(name: "Guest One", email: "guest-one-#{SecureRandom.hex(3)}@example.com", user_type: :guest)
    _property, room_type = create_property_with_room!(host: host, is_open: false)

    post login_url, params: { email: guest.email, password: "password123" }
    assert_redirected_to root_url

    assert_no_difference("Booking.count") do
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

    assert_redirected_to properties_url
    follow_redirect!
    assert_match "현재 준비중인 숙소는 예약할 수 없습니다.", response.body
  end
end
