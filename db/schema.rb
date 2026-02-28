# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_28_000100) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "amenities", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_amenities_on_name", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.text "assigned_room_numbers_text"
    t.string "booking_code", null: false
    t.datetime "cancelled_at"
    t.date "check_in_date", null: false
    t.date "check_out_date", null: false
    t.integer "coupon_id"
    t.datetime "created_at", null: false
    t.string "currency", limit: 5, default: "KRW", null: false
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "guest_count", default: 1, null: false
    t.text "guest_requests"
    t.integer "nights", default: 1, null: false
    t.decimal "original_price", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "room_count", default: 1, null: false
    t.integer "room_type_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["booking_code"], name: "index_bookings_on_booking_code", unique: true
    t.index ["check_in_date", "check_out_date"], name: "index_bookings_on_check_in_date_and_check_out_date"
    t.index ["coupon_id"], name: "index_bookings_on_coupon_id"
    t.index ["room_type_id"], name: "index_bookings_on_room_type_id"
    t.index ["user_id", "status"], name: "index_bookings_on_user_id_and_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "coupon_code", null: false
    t.datetime "created_at", null: false
    t.integer "discount_type", default: 0, null: false
    t.decimal "discount_value", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "max_discount", precision: 12, scale: 2
    t.decimal "min_order_amount", precision: 12, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.integer "usage_limit"
    t.integer "used_count", default: 0, null: false
    t.date "valid_from"
    t.date "valid_until"
    t.index ["coupon_code"], name: "index_coupons_on_coupon_code", unique: true
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entity_id", null: false
    t.integer "entity_type", default: 0, null: false
    t.text "image_url"
    t.boolean "is_thumbnail", default: false, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "entity_id"], name: "index_images_on_entity_type_and_entity_id"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 5, default: "KRW", null: false
    t.datetime "paid_at"
    t.integer "payment_method", default: 0, null: false
    t.integer "payment_status", default: 0, null: false
    t.string "pg_provider"
    t.string "pg_transaction_id"
    t.decimal "refund_amount", precision: 12, scale: 2, default: "0.0"
    t.datetime "refunded_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address", null: false
    t.decimal "avg_rating", precision: 3, scale: 2, default: "0.0", null: false
    t.time "check_in_time"
    t.time "check_out_time"
    t.string "city", null: false
    t.string "country", limit: 5, default: "KR"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "host_id", null: false
    t.boolean "is_approved", default: true, null: false
    t.boolean "is_open", default: true, null: false
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "property_name", null: false
    t.integer "property_type", default: 0, null: false
    t.integer "review_count", default: 0, null: false
    t.decimal "star_rating", precision: 2, scale: 1, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_properties_on_city"
    t.index ["host_id"], name: "index_properties_on_host_id"
    t.index ["is_open"], name: "index_properties_on_is_open"
    t.index ["property_name"], name: "index_properties_on_property_name"
  end

  create_table "property_amenities", force: :cascade do |t|
    t.integer "amenity_id", null: false
    t.datetime "created_at", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["amenity_id"], name: "index_property_amenities_on_amenity_id"
    t.index ["property_id", "amenity_id"], name: "index_property_amenities_on_property_id_and_amenity_id", unique: true
    t.index ["property_id"], name: "index_property_amenities_on_property_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "booking_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.text "host_reply"
    t.boolean "is_visible", default: true, null: false
    t.integer "property_id", null: false
    t.decimal "rating_cleanliness", precision: 2, scale: 1
    t.decimal "rating_location", precision: 2, scale: 1
    t.decimal "rating_overall", precision: 2, scale: 1, null: false
    t.decimal "rating_service", precision: 2, scale: 1
    t.decimal "rating_value", precision: 2, scale: 1
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["property_id"], name: "index_reviews_on_property_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "room_availabilities", force: :cascade do |t|
    t.integer "available_count", default: 0, null: false
    t.integer "booked_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.boolean "is_closed", default: false, null: false
    t.decimal "price_override", precision: 12, scale: 2
    t.integer "room_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["room_type_id", "date"], name: "index_room_availabilities_on_room_type_id_and_date", unique: true
    t.index ["room_type_id"], name: "index_room_availabilities_on_room_type_id"
  end

  create_table "room_types", force: :cascade do |t|
    t.decimal "area_sqm", precision: 6, scale: 2
    t.decimal "base_price", precision: 12, scale: 2, null: false
    t.integer "bed_type", default: 0, null: false
    t.string "cancellation_policy_name"
    t.datetime "created_at", null: false
    t.string "currency", limit: 5, default: "KRW", null: false
    t.integer "floor"
    t.boolean "is_smoking", default: false, null: false
    t.integer "max_guests", default: 2, null: false
    t.integer "property_id", null: false
    t.string "room_name", null: false
    t.text "room_numbers_text"
    t.integer "room_type", default: 0, null: false
    t.integer "total_count", default: 1, null: false
    t.datetime "updated_at", null: false
    t.string "view_type"
    t.index ["property_id"], name: "index_room_types_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 5, default: "KRW"
    t.string "email", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_verified", default: false, null: false
    t.string "language", limit: 10, default: "ko"
    t.datetime "last_login_at"
    t.string "name", null: false
    t.string "nationality", limit: 5, default: "KR"
    t.string "password_hash", null: false
    t.string "password_salt", null: false
    t.string "phone"
    t.text "profile_image_url"
    t.string "social_id"
    t.string "social_provider"
    t.datetime "updated_at", null: false
    t.integer "user_type", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["social_provider", "social_id"], name: "index_users_on_social_provider_and_social_id", unique: true
  end

  create_table "wishlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["property_id"], name: "index_wishlists_on_property_id"
    t.index ["user_id", "property_id"], name: "index_wishlists_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "coupons"
  add_foreign_key "bookings", "room_types"
  add_foreign_key "bookings", "users"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "users"
  add_foreign_key "properties", "users", column: "host_id"
  add_foreign_key "property_amenities", "amenities"
  add_foreign_key "property_amenities", "properties"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "properties"
  add_foreign_key "reviews", "users"
  add_foreign_key "room_availabilities", "room_types"
  add_foreign_key "room_types", "properties"
  add_foreign_key "wishlists", "properties"
  add_foreign_key "wishlists", "users"
end
