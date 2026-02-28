class RoomType < ApplicationRecord
  enum :room_type, { standard: 0, deluxe: 1, suite: 2, family: 3 }, default: :standard, validate: true
  enum :bed_type, { single: 0, double: 1, twin: 2, king: 3 }, default: :double, validate: true

  belongs_to :property
  has_many :bookings, dependent: :restrict_with_error
  has_many :room_availabilities, dependent: :destroy
  has_many :room_images, -> { where(entity_type: Image.entity_types[:room]).order(:sort_order, :id) },
           class_name: "Image",
           foreign_key: :entity_id,
           primary_key: :id,
           dependent: :destroy

  validates :room_name, :base_price, :max_guests, :total_count, presence: true
  validates :base_price, numericality: { greater_than: 0 }
  validates :max_guests, :total_count, numericality: { only_integer: true, greater_than: 0 }
  validate :room_numbers_count_matches_capacity

  def available_for?(check_in_date, check_out_date, requested_rooms)
    return false if check_in_date.blank? || check_out_date.blank? || requested_rooms.to_i <= 0

    ::RoomInventoryService.available_for?(self, check_in_date, check_out_date, requested_rooms)
  end

  def thumbnail_image
    room_images.find_by(is_thumbnail: true) || room_images.first
  end

  def stay_dates(check_in_date, check_out_date)
    return [] if check_in_date.blank? || check_out_date.blank? || check_out_date <= check_in_date

    (check_in_date...check_out_date).to_a
  end

  def room_numbers
    room_numbers_text.to_s
                     .split(/[\n,]/)
                     .map { |v| v.to_s.strip }
                     .reject(&:blank?)
                     .uniq
  end

  def available_room_numbers_for(booking)
    return room_numbers if room_numbers.blank?

    occupied = bookings.where.not(id: booking.id)
                      .where(status: %i[awaiting_payment confirmed])
                      .where("check_in_date < ? AND check_out_date > ?", booking.check_out_date, booking.check_in_date)
                      .flat_map(&:assigned_room_numbers)
                      .uniq

    room_numbers - occupied
  end

  private

  def room_numbers_count_matches_capacity
    return if room_numbers_text.blank?

    if room_numbers.size < total_count.to_i
      errors.add(:room_numbers_text, "호수 번호 개수는 총 객실 수(#{total_count})보다 적을 수 없습니다")
    end
  end
end
