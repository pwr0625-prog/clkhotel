require "test_helper"
require "stringio"

class ListingsHostAccessTest < ActionDispatch::IntegrationTest
  test "guest cannot access new listing page" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    get new_listing_url

    assert_redirected_to root_url
    follow_redirect!
    assert_select "p", /호스트만 접근할 수 있습니다/
  end

  test "host can access new listing page" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    get new_listing_url

    assert_response :success
    assert_select "h1", "hostel 등록"
  end

  test "host can create listing with photo" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    image = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/house.jpg"),
      "image/jpeg"
    )

    assert_difference("Listing.count", 1) do
      post listings_url, params: {
        listing: {
          title: "호스트 숙소",
          description: "깨끗하고 넓은 숙소",
          location: "부산",
          price: 90000,
          capacity: 4,
          photos: [image]
        }
      }
    end

    listing = Listing.order(:created_at).last
    assert_equal users(:two).id, listing.host_id
    assert listing.photos.attached?
    assert_redirected_to listing_url(listing)
  end

  test "host cannot create listing without photo" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    assert_no_difference("Listing.count") do
      post listings_url, params: {
        listing: {
          title: "사진 없는 숙소",
          description: "설명",
          location: "대전",
          price: 70000,
          capacity: 2
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h2", /error/
  end

  test "host can access edit page for own listing" do
    listing = create_listing_for(users(:two))

    post login_url, params: { email: users(:two).email, password: "password123" }
    get edit_listing_url(listing)

    assert_response :success
    assert_select "h1", "hostel 수정"
  end

  test "host can update own listing" do
    listing = create_listing_for(users(:two))

    post login_url, params: { email: users(:two).email, password: "password123" }
    patch listing_url(listing), params: {
      listing: {
        title: "수정된 hostel",
        description: "설명 수정",
        location: "제주",
        price: 120000,
        capacity: 6
      }
    }

    assert_redirected_to listing_url(listing)
    follow_redirect!
    assert_select "h1", "수정된 hostel"
    assert_select "p", /제주/
  end

  test "guest cannot access edit page" do
    listing = create_listing_for(users(:two))

    post login_url, params: { email: users(:one).email, password: "password123" }
    get edit_listing_url(listing)

    assert_redirected_to root_url
    follow_redirect!
    assert_select "p", /호스트만 접근할 수 있습니다/
  end

  test "host cannot edit another hosts listing" do
    other_host = User.create!(
      name: "Host Two",
      email: "host2@example.com",
      role: :host,
      password: "password123",
      password_confirmation: "password123"
    )
    listing = create_listing_for(other_host, title: "다른 호스트 숙소")

    post login_url, params: { email: users(:two).email, password: "password123" }
    get edit_listing_url(listing)

    assert_redirected_to listings_url
    follow_redirect!
    assert_select "p", /본인이 등록한 hostel만 수정할 수 있습니다/
  end

  private

  def create_listing_for(host, title: "테스트 hostel")
    listing = host.hosted_listings.new(
      title: title,
      description: "설명",
      location: "서울",
      price: 100000,
      capacity: 3
    )
    listing.photos.attach(
      io: StringIO.new(File.binread(Rails.root.join("test/fixtures/files/house.jpg"))),
      filename: "house.jpg",
      content_type: "image/jpeg"
    )
    listing.save!
    listing
  end
end
