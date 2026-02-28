puts "Seeding ClkHotel..."

[Amenity, PropertyAmenity, Review, Payment, Booking, RoomAvailability, RoomType, Wishlist, Property, Coupon, User].each(&:delete_all)

wifi = Amenity.create!(name: "Wi-Fi", category: "basic", icon: "wifi")
parking = Amenity.create!(name: "주차", category: "basic", icon: "parking")
breakfast = Amenity.create!(name: "조식", category: "food", icon: "breakfast")
pool = Amenity.create!(name: "수영장", category: "leisure", icon: "pool")

host = User.create!(
  name: "호스트 김",
  email: "host@clkhotel.local",
  phone: "010-1111-2222",
  user_type: :host,
  password: "password123",
  password_confirmation: "password123",
  is_verified: true,
  currency: "KRW"
)

guest = User.create!(
  name: "게스트 이",
  email: "guest@clkhotel.local",
  phone: "010-3333-4444",
  user_type: :guest,
  password: "password123",
  password_confirmation: "password123",
  is_verified: true,
  currency: "KRW"
)

admin = User.create!(
  name: "관리자 박",
  email: "admin@clkhotel.local",
  phone: "010-5555-6666",
  user_type: :admin,
  password: "password123",
  password_confirmation: "password123",
  is_verified: true,
  currency: "KRW"
)

coupon = Coupon.create!(
  coupon_code: "WELCOME10",
  discount_type: :percent,
  discount_value: 10,
  min_order_amount: 50_000,
  max_discount: 30_000,
  valid_from: Date.current - 30,
  valid_until: Date.current + 365,
  usage_limit: 1000
)

seoul = host.properties.create!(
  property_name: "Clk Hotel Seoul Central",
  property_type: :hotel,
  description: "도심 접근성이 좋은 테스트 숙소입니다. 검색/예약/결제/리뷰 흐름 점검용 데이터입니다.",
  country: "KR",
  city: "서울",
  address: "서울 중구 테스트로 101",
  star_rating: 4.5,
  check_in_time: "15:00",
  check_out_time: "11:00",
  is_approved: true
)

busan = host.properties.create!(
  property_name: "Clk Ocean Busan",
  property_type: :resort,
  description: "바다 전망 중심의 리조트형 테스트 숙소입니다.",
  country: "KR",
  city: "부산",
  address: "부산 해운대구 샘플해변로 20",
  star_rating: 4.0,
  check_in_time: "15:00",
  check_out_time: "11:00",
  is_approved: true
)

[[seoul, [wifi, parking, breakfast]], [busan, [wifi, pool, breakfast]]].each do |property, amenities|
  amenities.each { |amenity| PropertyAmenity.find_or_create_by!(property:, amenity:) }
end

standard = seoul.room_types.create!(
  room_name: "스탠다드 더블",
  room_type: :standard,
  bed_type: :double,
  max_guests: 2,
  base_price: 120_000,
  currency: "KRW",
  area_sqm: 24,
  floor: 8,
  view_type: "City",
  total_count: 5,
  is_smoking: false,
  cancellation_policy_name: "체크인 1일 전 무료취소"
)

suite = seoul.room_types.create!(
  room_name: "패밀리 스위트",
  room_type: :suite,
  bed_type: :king,
  max_guests: 4,
  base_price: 260_000,
  currency: "KRW",
  area_sqm: 48,
  floor: 12,
  view_type: "City",
  total_count: 2,
  is_smoking: false,
  cancellation_policy_name: "체크인 3일 전 무료취소"
)

busan.room_types.create!(
  room_name: "오션 디럭스 트윈",
  room_type: :deluxe,
  bed_type: :twin,
  max_guests: 3,
  base_price: 180_000,
  currency: "KRW",
  area_sqm: 30,
  floor: 5,
  view_type: "Ocean",
  total_count: 4,
  is_smoking: false,
  cancellation_policy_name: "체크인 2일 전 무료취소"
)

booking = Booking.create!(
  user: guest,
  room_type: standard,
  coupon: coupon,
  check_in_date: Date.current + 7,
  check_out_date: Date.current + 9,
  guest_count: 2,
  room_count: 1,
  guest_requests: "고층 객실 요청",
  status: :confirmed
)

Payment.create!(
  booking: booking,
  user: guest,
  payment_method: :card,
  payment_status: :success,
  amount: booking.total_price,
  currency: booking.currency,
  pg_transaction_id: "SEEDTXN001",
  pg_provider: "mock_card_pg",
  paid_at: Time.current
)

completed_booking = Booking.create!(
  user: guest,
  room_type: suite,
  check_in_date: Date.current + 1,
  check_out_date: Date.current + 2,
  guest_count: 3,
  room_count: 1,
  status: :completed
)

Review.create!(
  booking: completed_booking,
  user: guest,
  property: seoul,
  rating_overall: 4.5,
  rating_cleanliness: 4.5,
  rating_location: 5.0,
  rating_service: 4.5,
  rating_value: 4.0,
  content: "체크인 과정이 빠르고 위치가 좋아요.",
  is_visible: true
)

Wishlist.find_or_create_by!(user: guest, property: busan)

puts "Seed complete."
puts "host: host@clkhotel.local / password123"
puts "guest: guest@clkhotel.local / password123"
puts "admin: admin@clkhotel.local / password123"
