require "test_helper"

class BookingFlowTest < ActionDispatch::IntegrationTest
  def create_listing_for_host!(title: "예약 테스트 숙소")
    listing = Listing.new(
      host: users(:two),
      title: title,
      description: "설명",
      location: "서울",
      price: 80000,
      capacity: 4
    )
    listing.photos.attach(io: StringIO.new("img"), filename: "z.jpg", content_type: "image/jpeg")
    listing.save!
    listing
  end

  test "guest can request booking and total is calculated" do
    listing = create_listing_for_host!

    post login_url, params: { email: users(:one).email, password: "password123" }

    assert_difference("Booking.count", 1) do
      post listing_bookings_url(listing), params: {
        booking: {
          check_in: "2026-04-20",
          check_out: "2026-04-23",
          guests_count: 2
        }
      }
    end

    booking = Booking.order(:created_at).last
    assert_equal "pending", booking.status
    assert_equal BigDecimal("240000.0"), booking.total_price
    assert_redirected_to listing_url(listing)
  end

  test "host can confirm and reject booking requests" do
    listing = create_listing_for_host!
    booking_to_confirm = Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 5, 1),
      check_out: Date.new(2026, 5, 3),
      guests_count: 2
    )
    booking_to_reject = Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 5, 5),
      check_out: Date.new(2026, 5, 6),
      guests_count: 1
    )

    post login_url, params: { email: users(:two).email, password: "password123" }
    patch confirm_booking_url(booking_to_confirm)

    assert_redirected_to listing_url(listing)
    assert_equal "confirmed", booking_to_confirm.reload.status

    patch reject_booking_url(booking_to_reject)
    assert_redirected_to listing_url(listing)
    assert_equal "cancelled", booking_to_reject.reload.status
  end

  test "listing detail shows availability check result" do
    listing = create_listing_for_host!
    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 6, 10),
      check_out: Date.new(2026, 6, 12),
      guests_count: 2,
      status: :confirmed
    )

    get listing_url(listing), params: { check_in: "2026-06-11", check_out: "2026-06-13" }

    assert_response :success
    assert_select "p", /이미 예약되어 있습니다/
  end
end
