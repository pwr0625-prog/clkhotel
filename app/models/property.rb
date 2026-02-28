class Property < ApplicationRecord
  enum :property_type, { hotel: 0, pension: 1, motel: 2, resort: 3, guesthouse: 4 }, default: :hotel, validate: true

  belongs_to :host, class_name: "User", inverse_of: :properties
  has_many :room_types, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_many :bookings, through: :room_types
  has_many :property_amenities, dependent: :destroy
  has_many :amenities, through: :property_amenities

  validates :property_name, :city, :address, presence: true

  scope :approved, -> { where(is_approved: true) }
  scope :open_for_guest, -> { where(is_open: true) }

  def closed_for_guest?
    !is_open?
  end

  def min_price
    room_types.minimum(:base_price)
  end

  def property_image
    Image.find_by(entity_type: :property, entity_id: id, is_thumbnail: true) ||
      Image.where(entity_type: :property, entity_id: id).order(:sort_order, :id).first
  end

  def recalculate_rating!
    visible_reviews = reviews.where(is_visible: true)
    update_columns(
      avg_rating: (visible_reviews.average(:rating_overall) || 0).to_f.round(2),
      review_count: visible_reviews.count
    )
  end
end
