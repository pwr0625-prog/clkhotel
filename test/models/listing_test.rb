require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "is valid with required attributes and a photo" do
    listing = Listing.new(
      host: users(:two),
      title: "테스트 숙소",
      description: "아늑한 공간",
      location: "서울",
      price: 120000,
      capacity: 3
    )
    listing.photos.attach(
      io: StringIO.new("fake-image"),
      filename: "room.jpg",
      content_type: "image/jpeg"
    )

    assert listing.valid?
  end

  test "is invalid without photos" do
    listing = Listing.new(
      host: users(:two),
      title: "테스트 숙소",
      description: "아늑한 공간",
      location: "서울",
      price: 120000,
      capacity: 3
    )

    assert_not listing.valid?
    assert_includes listing.errors[:photos], "must include at least one image"
  end
end
