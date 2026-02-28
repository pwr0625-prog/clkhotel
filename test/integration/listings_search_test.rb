require "test_helper"

class ListingsSearchTest < ActionDispatch::IntegrationTest
  test "guest can access search page" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    get search_listings_url

    assert_response :success
    assert_select "h1", "숙소 검색 (게스트)"
  end

  test "host cannot access search page" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    get search_listings_url

    assert_redirected_to root_url
    follow_redirect!
    assert_select "p", /게스트만 사용할 수 있습니다/
  end

  test "search filters by location guests and dates" do
    host = users(:two)

    listing_available = Listing.new(
      host: host,
      title: "강남 스테이",
      description: "조용한 숙소",
      location: "서울 강남",
      price: 110000,
      capacity: 2
    )
    listing_available.photos.attach(io: StringIO.new("image-a"), filename: "a.jpg", content_type: "image/jpeg")
    listing_available.save!

    listing_booked = Listing.new(
      host: host,
      title: "마포 하우스",
      description: "넓은 숙소",
      location: "서울 마포",
      price: 130000,
      capacity: 4
    )
    listing_booked.photos.attach(io: StringIO.new("image-b"), filename: "b.jpg", content_type: "image/jpeg")
    listing_booked.save!

    Booking.create!(
      listing: listing_booked,
      guest: users(:one),
      check_in: Date.new(2026, 3, 10),
      check_out: Date.new(2026, 3, 15),
      guests_count: 2,
      status: :confirmed
    )

    post login_url, params: { email: users(:one).email, password: "password123" }
    get search_listings_url, params: {
      search: {
        location: "서울",
        check_in: "2026-03-12",
        check_out: "2026-03-13",
        guests_count: "2"
      }
    }

    assert_response :success
    assert_select "h3", /강남 스테이/
    assert_select "h3", text: /마포 하우스/, count: 0
  end
end
