class Image < ApplicationRecord
  enum :entity_type, { property: 0, room: 1, review: 2 }, default: :room, validate: true

  has_one_attached :file

  scope :ordered, -> { order(:sort_order, :id) }

  validates :entity_type, :entity_id, presence: true
  validates :sort_order, numericality: { only_integer: true }

  before_validation :normalize_url
  before_save :ensure_single_thumbnail_for_entity, if: :is_thumbnail?
  validate :file_or_image_url_present

  def display_source
    return file if file.attached?

    image_url.presence
  end

  private

  def normalize_url
    self.image_url = image_url.to_s.strip
  end

  def ensure_single_thumbnail_for_entity
    self.class.where(entity_type:, entity_id:)
              .where.not(id:)
              .update_all(is_thumbnail: false)
  end

  def file_or_image_url_present
    return if file.attached? || image_url.present?

    errors.add(:base, "이미지 파일 또는 이미지 URL이 필요합니다")
  end
end
