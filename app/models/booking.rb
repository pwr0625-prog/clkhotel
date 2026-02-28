class Booking < ApplicationRecord
  enum :status, {
    pending: 0,
    confirmed: 1,
    cancelled: 2,
    completed: 3,
    no_show: 4,
    awaiting_payment: 5
  }, default: :pending, validate: true

  belongs_to :user
  belongs_to :room_type
  belongs_to :coupon, optional: true
  has_one :payment, dependent: :destroy
  has_one :review, dependent: :destroy

  delegate :property, to: :room_type

  before_validation :assign_booking_code, on: :create
  before_validation :calculate_pricing

  validates :check_in_date, :check_out_date, :guest_count, :room_count, presence: true
  validates :guest_count, :room_count, numericality: { only_integer: true, greater_than: 0 }
  validates :booking_code, presence: true, uniqueness: true
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  validate :valid_stay_dates
  validate :within_room_capacity
  validate :room_availability

  scope :active_states, -> { where(status: %i[pending awaiting_payment confirmed]) }

  validate :assigned_room_numbers_valid

  def stay_dates
    return [] if check_in_date.blank? || check_out_date.blank? || check_out_date <= check_in_date

    (check_in_date...check_out_date).to_a
  end

  def inventory_holding?
    pending? || awaiting_payment? || confirmed?
  end

  def assigned_room_numbers
    assigned_room_numbers_text.to_s
                             .split(/[\n,]/)
                             .map { |v| v.to_s.strip }
                             .reject(&:blank?)
                             .uniq
  end

  def assigned_room_numbers=(values)
    normalized = Array(values)
      .flat_map { |v| v.to_s.split(/[\n,]/) }
      .map(&:strip)
      .reject(&:blank?)
      .uniq

    self.assigned_room_numbers_text = normalized.join(", ")
  end

  def status_label
    {
      "pending" => "예약확정 대기",
      "awaiting_payment" => "결제/취소 단계",
      "confirmed" => "예약 확정",
      "cancelled" => "취소",
      "completed" => "숙박 완료",
      "no_show" => "노쇼"
    }.fetch(status, status)
  end

  def can_review?
    completed? || confirmed?
  end

  private

  def assign_booking_code
    return if booking_code.present?

    self.booking_code = loop do
      code = "BK#{Time.current.strftime('%y%m%d')}#{SecureRandom.random_number(10_000).to_s.rjust(4, '0')}"
      break code unless self.class.exists?(booking_code: code)
    end
  end

  def calculate_pricing
    return if room_type.blank? || check_in_date.blank? || check_out_date.blank?

    self.nights = (check_out_date - check_in_date).to_i
    return if nights <= 0

    self.currency ||= room_type.currency
    self.original_price = room_type.base_price.to_d * nights * room_count.to_i
    self.discount_amount = applicable_coupon_discount
    self.total_price = [original_price.to_d - discount_amount.to_d, 0].max
  end

  def applicable_coupon_discount
    return 0.to_d if coupon.blank?
    return 0.to_d unless coupon.active_on?(Date.current)

    coupon.discount_for(original_price.to_d)
  end

  def valid_stay_dates
    return if check_in_date.blank? || check_out_date.blank?

    errors.add(:check_out_date, "체크아웃은 체크인 이후여야 합니다") unless check_out_date > check_in_date
    errors.add(:check_in_date, "오늘 이후 날짜를 선택하세요") if new_record? && check_in_date < Date.current
  end

  def within_room_capacity
    return if room_type.blank? || guest_count.blank? || room_count.blank?

    if guest_count.to_i > room_type.max_guests * room_count.to_i
      errors.add(:guest_count, "선택한 객실 수의 최대 투숙 가능 인원을 초과했습니다")
    end
  end

  def room_availability
    return if room_type.blank? || check_in_date.blank? || check_out_date.blank? || room_count.blank?
    return if errors.any?

    service = ::RoomInventoryService.new
    stay_dates.each do |date|
      snapshot = service.snapshot_for(room_type, date, exclude_booking_id: persisted? ? id : nil)
      if snapshot[:is_closed]
        errors.add(:base, "#{date} 날짜는 판매 마감입니다")
        break
      end

      if snapshot[:sellable_count] < room_count.to_i
        errors.add(:base, "선택한 기간에 남은 객실 수가 부족합니다")
        break
      end
    end
  end

  def assigned_room_numbers_valid
    return if assigned_room_numbers_text.blank?
    return if room_type.blank?

    if assigned_room_numbers.size != room_count.to_i
      errors.add(:assigned_room_numbers_text, "배정 호수 개수는 예약 객실 수와 같아야 합니다")
      return
    end

    invalid_numbers = assigned_room_numbers - room_type.room_numbers
    if room_type.room_numbers.present? && invalid_numbers.any?
      errors.add(:assigned_room_numbers_text, "등록되지 않은 호수 번호가 포함되어 있습니다: #{invalid_numbers.join(', ')}")
    end

    overlap_scope = room_type.bookings.where.not(id: id)
                          .where(status: %i[awaiting_payment confirmed])
                          .where("check_in_date < ? AND check_out_date > ?", check_out_date, check_in_date)

    occupied_numbers = overlap_scope.flat_map(&:assigned_room_numbers)
    conflict = assigned_room_numbers & occupied_numbers
    errors.add(:assigned_room_numbers_text, "이미 배정된 호수입니다: #{conflict.join(', ')}") if conflict.any?
  end
end
