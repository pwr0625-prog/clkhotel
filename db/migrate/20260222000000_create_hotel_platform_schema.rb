class CreateHotelPlatformSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :users, if_not_exists: true do |t|
      t.string :email, null: false
      t.string :password_hash, null: false
      t.string :password_salt, null: false
      t.string :name, null: false
      t.string :phone
      t.text :profile_image_url
      t.integer :user_type, null: false, default: 0
      t.string :social_provider
      t.string :social_id
      t.string :nationality, limit: 5, default: "KR"
      t.string :language, limit: 10, default: "ko"
      t.string :currency, limit: 5, default: "KRW"
      t.boolean :is_verified, null: false, default: false
      t.boolean :is_active, null: false, default: true
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :users, :email, unique: true, if_not_exists: true
    add_index :users, %i[social_provider social_id], unique: true, if_not_exists: true

    create_table :properties, if_not_exists: true do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :property_name, null: false
      t.integer :property_type, null: false, default: 0
      t.text :description
      t.string :country, limit: 5, default: "KR"
      t.string :city, null: false
      t.string :address, null: false
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.decimal :star_rating, precision: 2, scale: 1, default: 0
      t.time :check_in_time
      t.time :check_out_time
      t.boolean :is_approved, null: false, default: true
      t.decimal :avg_rating, precision: 3, scale: 2, null: false, default: 0
      t.integer :review_count, null: false, default: 0
      t.timestamps
    end
    add_index :properties, :city, if_not_exists: true
    add_index :properties, :property_name, if_not_exists: true

    create_table :coupons, if_not_exists: true do |t|
      t.string :coupon_code, null: false
      t.integer :discount_type, null: false, default: 0
      t.decimal :discount_value, precision: 10, scale: 2, null: false, default: 0
      t.decimal :min_order_amount, precision: 12, scale: 2, default: 0
      t.decimal :max_discount, precision: 12, scale: 2
      t.date :valid_from
      t.date :valid_until
      t.integer :usage_limit
      t.integer :used_count, null: false, default: 0
      t.timestamps
    end
    add_index :coupons, :coupon_code, unique: true, if_not_exists: true

    create_table :room_types, if_not_exists: true do |t|
      t.references :property, null: false, foreign_key: true
      t.string :room_name, null: false
      t.integer :room_type, null: false, default: 0
      t.integer :bed_type, null: false, default: 0
      t.integer :max_guests, null: false, default: 2
      t.decimal :base_price, precision: 12, scale: 2, null: false
      t.string :currency, limit: 5, null: false, default: "KRW"
      t.decimal :area_sqm, precision: 6, scale: 2
      t.integer :floor
      t.string :view_type
      t.integer :total_count, null: false, default: 1
      t.boolean :is_smoking, null: false, default: false
      t.string :cancellation_policy_name
      t.timestamps
    end

    create_table :room_availabilities, if_not_exists: true do |t|
      t.references :room_type, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :available_count, null: false, default: 0
      t.integer :booked_count, null: false, default: 0
      t.decimal :price_override, precision: 12, scale: 2
      t.boolean :is_closed, null: false, default: false
      t.timestamps
    end
    add_index :room_availabilities, %i[room_type_id date], unique: true, if_not_exists: true

    create_table :bookings, if_not_exists: true do |t|
      t.string :booking_code, null: false
      t.references :user, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.references :coupon, foreign_key: true
      t.date :check_in_date, null: false
      t.date :check_out_date, null: false
      t.integer :nights, null: false, default: 1
      t.integer :guest_count, null: false, default: 1
      t.integer :room_count, null: false, default: 1
      t.decimal :original_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_price, precision: 12, scale: 2, null: false, default: 0
      t.string :currency, limit: 5, null: false, default: "KRW"
      t.integer :status, null: false, default: 0
      t.text :guest_requests
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :bookings, :booking_code, unique: true, if_not_exists: true
    add_index :bookings, %i[user_id status], if_not_exists: true
    add_index :bookings, %i[check_in_date check_out_date], if_not_exists: true

    create_table :payments, if_not_exists: true do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.integer :payment_status, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, limit: 5, null: false, default: "KRW"
      t.string :pg_transaction_id
      t.string :pg_provider
      t.decimal :refund_amount, precision: 12, scale: 2, default: 0
      t.datetime :refunded_at
      t.datetime :paid_at
      t.timestamps
    end
    add_index :payments, :booking_id, unique: true, if_not_exists: true

    create_table :reviews, if_not_exists: true do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.decimal :rating_overall, precision: 2, scale: 1, null: false
      t.decimal :rating_cleanliness, precision: 2, scale: 1
      t.decimal :rating_location, precision: 2, scale: 1
      t.decimal :rating_service, precision: 2, scale: 1
      t.decimal :rating_value, precision: 2, scale: 1
      t.text :content
      t.text :host_reply
      t.boolean :is_visible, null: false, default: true
      t.timestamps
    end
    add_index :reviews, :booking_id, unique: true, if_not_exists: true

    create_table :amenities, if_not_exists: true do |t|
      t.string :name, null: false
      t.string :category
      t.string :icon
      t.timestamps
    end
    add_index :amenities, :name, unique: true, if_not_exists: true

    create_table :property_amenities, if_not_exists: true do |t|
      t.references :property, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true
      t.timestamps
    end
    add_index :property_amenities, %i[property_id amenity_id], unique: true, if_not_exists: true

    create_table :images, if_not_exists: true do |t|
      t.integer :entity_type, null: false, default: 0
      t.bigint :entity_id, null: false
      t.text :image_url
      t.boolean :is_thumbnail, null: false, default: false
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end
    add_index :images, %i[entity_type entity_id], if_not_exists: true

    create_table :wishlists, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.timestamps
    end
    add_index :wishlists, %i[user_id property_id], unique: true, if_not_exists: true
  end
end
