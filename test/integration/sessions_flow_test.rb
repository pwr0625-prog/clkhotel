require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  test "renders login page" do
    get login_url

    assert_response :success
    assert_select "h1", "로그인"
  end

  test "can login with valid credentials" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select "p", /로그인 사용자:/
    assert_select "strong", users(:one).email
  end

  test "rejects invalid credentials" do
    post login_url, params: { email: users(:one).email, password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_select "p", /올바르지 않습니다/
  end

  test "can logout" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    delete logout_url

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select "a", "로그인"
  end
end
