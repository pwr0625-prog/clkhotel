require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  self.fixture_paths = []

  def build_host(email: "host-#{SecureRandom.hex(4)}@example.com")
    User.new(
      name: "Host User",
      email: email,
      user_type: :host,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def build_property(host:, is_open: true)
    Property.new(
      host: host,
      property_name: "테스트 호텔",
      city: "서울",
      address: "서울시 중구 1",
      is_open: is_open
    )
  end

  test "new property defaults to open" do
    host = build_host
    host.save!

    property = build_property(host: host)
    property.save!

    assert property.is_open?
    assert_not property.closed_for_guest?
  end

  test "open_for_guest scope returns only open properties" do
    host = build_host
    host.save!

    open_property = build_property(host: host, is_open: true)
    closed_property = build_property(host: host, is_open: false)
    open_property.save!
    closed_property.save!

    scoped = Property.open_for_guest
    assert_includes scoped, open_property
    assert_not_includes scoped, closed_property
  end
end
