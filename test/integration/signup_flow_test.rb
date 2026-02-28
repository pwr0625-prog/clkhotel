require "test_helper"

class SignupFlowTest < ActionDispatch::IntegrationTest
  test "renders signup page" do
    get signup_url

    assert_response :success
    assert_select "h1", "회원가입"
  end

  test "can sign up as guest" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "새 게스트",
          email: "new@example.com",
          role: "guest",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    created_user = User.order(:created_at).last
    assert_equal "guest", created_user.role
    assert_redirected_to user_url(created_user)
    follow_redirect!
    assert_response :success
    assert_select "h1", "회원가입 완료"
    assert_select "strong", "새 게스트"
    assert_select "strong", "new@example.com"
    assert_select "p", /회원 유형: guest/
    assert_select "a", "로그인"
  end

  test "can sign up as host" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "새 호스트",
          email: "host-new@example.com",
          role: "host",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    created_user = User.order(:created_at).last
    assert_equal "host", created_user.role
  end

  test "rejects invalid signup" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "",
          email: "bad-email",
          role: "invalid-role",
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h2", /error/
  end
end
