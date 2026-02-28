require "test_helper"

class HostPropertyStatusUpdateTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []

  def create_host!(email: "host-#{SecureRandom.hex(3)}@example.com")
    User.create!(
      name: "Host User",
      email: email,
      user_type: :host,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_property!(host:, is_open: true)
    Property.create!(
      host: host,
      property_name: "상태변경 테스트 호텔",
      city: "서울",
      address: "서울시 종로구 1",
      is_open: is_open
    )
  end

  test "host can change property open close status" do
    host = create_host!
    property = create_property!(host: host, is_open: true)

    post login_url, params: { email: host.email, password: "password123" }
    assert_redirected_to root_url

    patch host_property_url(property), params: {
      property: {
        property_name: property.property_name,
        property_type: property.property_type,
        country: property.country,
        city: property.city,
        address: property.address,
        star_rating: property.star_rating,
        check_in_time: property.check_in_time,
        check_out_time: property.check_out_time,
        description: property.description,
        is_open: "false"
      }
    }

    assert_redirected_to host_property_url(property)
    assert_equal false, property.reload.is_open

    patch host_property_url(property), params: {
      property: {
        property_name: property.property_name,
        property_type: property.property_type,
        country: property.country,
        city: property.city,
        address: property.address,
        star_rating: property.star_rating,
        check_in_time: property.check_in_time,
        check_out_time: property.check_out_time,
        description: property.description,
        is_open: "true"
      }
    }

    assert_redirected_to host_property_url(property)
    assert_equal true, property.reload.is_open
  end
end
