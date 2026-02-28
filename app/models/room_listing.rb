class RoomListing < ApplicationRecord
  self.primary_key = %i[host_id room_type]

  belongs_to :host, class_name: "User", foreign_key: :host_id, inverse_of: :room_listings
  belongs_to :hotel_listing, class_name: "Listing", inverse_of: :room_listings

  validates :room_type, presence: true
end
