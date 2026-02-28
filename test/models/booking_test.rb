require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "calculates total_price by nights" do
    listing = Listing.new(
      host: users(:two),
      title: "테스트 숙소",
      description: "설명",
      location: "서울",
      price: 100000,
      capacity: 3
    )
    listing.photos.attach(io: StringIO.new("img"), filename: "x.jpg", content_type: "image/jpeg")
    listing.save!

    booking = Booking.new(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 4, 1),
      check_out: Date.new(2026, 4, 4),
      guests_count: 2
    )

    assert booking.valid?
    assert_equal BigDecimal("300000.0"), booking.total_price
  end

  test "rejects overlapping dates with active bookings" do
    listing = Listing.new(
      host: users(:two),
      title: "테스트 숙소",
      description: "설명",
      location: "서울",
      price: 100000,
      capacity: 3
    )
    listing.photos.attach(io: StringIO.new("img"), filename: "y.jpg", content_type: "image/jpeg")
    listing.save!

    Booking.create!(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 4, 10),
      check_out: Date.new(2026, 4, 12),
      guests_count: 2,
      status: :confirmed
    )

    overlap = Booking.new(
      listing: listing,
      guest: users(:one),
      check_in: Date.new(2026, 4, 11),
      check_out: Date.new(2026, 4, 13),
      guests_count: 1
    )

    assert_not overlap.valid?
    assert_includes overlap.errors[:base], "selected dates are not available"
  end
end
