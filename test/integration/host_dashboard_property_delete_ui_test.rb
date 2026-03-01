require "test_helper"

class HostDashboardPropertyDeleteUiTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []

  def create_host!
    User.create!(
      name: "Host User",
      email: "host-dashboard-ui-#{SecureRandom.hex(3)}@example.com",
      user_type: :host,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_property!(host:)
    Property.create!(
      host: host,
      property_name: "대시보드 삭제 버튼 테스트 숙소",
      city: "서울",
      address: "서울시 중구 100",
      is_open: true
    )
  end

  test "host dashboard shows delete button for each property" do
    host = create_host!
    property = create_property!(host: host)

    post login_url, params: { email: host.email, password: "password123" }
    assert_redirected_to root_url

    get host_root_url
    assert_response :success
    assert_select "form[action='#{host_property_path(property)}'] button", text: "숙소 삭제", count: 1
  end
end
