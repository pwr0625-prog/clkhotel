class Listing < ApplicationRecord
  self.table_name = "hotel_listings"
  belongs_to :host, class_name: "User", inverse_of: :hosted_listings
  has_many :bookings, dependent: :destroy
  has_many :room_listings, foreign_key: :hotel_listing_id, inverse_of: :hotel_listing, dependent: :destroy
  has_many_attached :photos

  validates :title, :description, :location, :price, :capacity, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }

  validate :must_have_at_least_one_photo

  def available_for?(check_in, check_out)
    return false if check_in.blank? || check_out.blank? || check_out <= check_in

    bookings.where.not(status: :cancelled)
            .where("check_in < ? AND check_out > ?", check_out, check_in)
            .none?
  end

  private

  def must_have_at_least_one_photo
    errors.add(:photos, "must include at least one image") unless photos.attached?
  end
end
