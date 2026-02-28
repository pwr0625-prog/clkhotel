require "test_helper"

class BookingManagementTest < ActionDispatch::IntegrationTest
  def create_listing_for_host!(title: "관리 테스트 숙소")
    listing = Listing.new(
      host: users(:two),
      title: title,
      description: "설명",
      location: "서울",
      price: 75000,
      capacity: 3
    )
    listing.photos.attach(io: StringIO.new("img"), filename: "m.jpg", content_type: "image/jpeg")
    listing.save!
    listing
  end

  test "guest can view own bookings with status labels" do
    listing = create_listing_for_host!
    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 7, 1),
      check_out: Date.new(2026, 7, 3),
      guests_count: 2,
      status: :pending
    )
    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 7, 10),
      check_out: Date.new(2026, 7, 12),
      guests_count: 1,
      status: :confirmed
    )
    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 7, 20),
      check_out: Date.new(2026, 7, 21),
      guests_count: 1,
      status: :cancelled
    )

    post login_url, params: { email: users(:one).email, password: "password123" }
    get my_bookings_url

    assert_response :success
    assert_select "h1", "내 예약 목록"
    assert_select "strong", text: "대기", count: 1
    assert_select "strong", text: "확정", count: 1
    assert_select "strong", text: "취소", count: 1
  end

  test "host can view booking requests list" do
    listing = create_listing_for_host!
    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 8, 1),
      check_out: Date.new(2026, 8, 2),
      guests_count: 1,
      status: :pending
    )

    post login_url, params: { email: users(:two).email, password: "password123" }
    get requests_bookings_url

    assert_response :success
    assert_select "h1", "예약 요청 목록"
    assert_select "strong", text: "대기", count: 1
  end

  test "guest cannot access host requests page" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    get requests_bookings_url

    assert_redirected_to root_url
    follow_redirect!
    assert_select "p", /호스트만 접근할 수 있습니다/
  end

  test "host cannot access guest my bookings page" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    get my_bookings_url

    assert_redirected_to root_url
    follow_redirect!
    assert_select "p", /게스트만 사용할 수 있습니다/
  end
end
