require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with name email and password" do
    user = User.new(name: "테스터", email: "user@example.com", password: "password123", password_confirmation: "password123")

    assert user.valid?
  end

  test "is invalid without name" do
    user = User.new(email: "user@example.com", password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "defaults role to guest" do
    user = User.create!(name: "기본역할", email: "default-role@example.com", password: "password123", password_confirmation: "password123")

    assert user.guest?
  end

  test "supports host role" do
    user = User.create!(name: "호스트", email: "host-role@example.com", role: :host, password: "password123", password_confirmation: "password123")

    assert user.host?
  end

  test "normalizes email" do
    user = User.create!(name: "정규화", email: "  Mixed@Example.COM ", password: "password123", password_confirmation: "password123")

    assert_equal "mixed@example.com", user.email
  end

  test "is invalid with duplicate email" do
    User.create!(name: "중복1", email: "dup@example.com", password: "password123", password_confirmation: "password123")
    user = User.new(name: "중복2", email: "DUP@example.com", password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "is invalid with short password" do
    user = User.new(name: "짧은비번", email: "user2@example.com", password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end
end
