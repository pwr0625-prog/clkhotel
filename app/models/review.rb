class Review < ApplicationRecord
  belongs_to :booking
  belongs_to :user
  belongs_to :property

  validates :rating_overall, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :content, length: { maximum: 2000 }

  after_commit :refresh_property_rating, on: %i[create update destroy]

  private

  def refresh_property_rating
    property.recalculate_rating!
  end
end
