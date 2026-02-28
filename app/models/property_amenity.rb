class PropertyAmenity < ApplicationRecord
  belongs_to :property
  belongs_to :amenity

  validates :amenity_id, uniqueness: { scope: :property_id }
end
