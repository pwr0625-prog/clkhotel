class RoomAvailability < ApplicationRecord
  belongs_to :room_type

  validates :date, presence: true, uniqueness: { scope: :room_type_id }
  validates :available_count, :booked_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :booked_count_within_available_count

  def remaining_count
    [effective_available_count - booked_count.to_i, 0].max
  end

  def effective_available_count
    available_count.nil? ? room_type.total_count : available_count
  end

  def sellable?(requested_rooms)
    return false if is_closed?

    remaining_count >= requested_rooms.to_i
  end

  private

  def booked_count_within_available_count
    return if available_count.blank? || booked_count.blank?
    return if booked_count <= available_count

    errors.add(:booked_count, "예약 수량이 가용 객실 수를 초과할 수 없습니다")
  end
end
