class Coupon < ApplicationRecord
  enum :discount_type, { percent: 0, fixed: 1 }, default: :percent, validate: true

  has_many :bookings, dependent: :nullify

  before_validation { self.coupon_code = coupon_code.to_s.strip.upcase }

  validates :coupon_code, presence: true, uniqueness: true
  validates :discount_value, numericality: { greater_than: 0 }

  def active_on?(date)
    target = (date || Date.current)
    return false if valid_from.present? && target < valid_from
    return false if valid_until.present? && target > valid_until
    return false if usage_limit.present? && used_count >= usage_limit

    true
  end

  def discount_for(amount)
    total = amount.to_d
    return 0.to_d if min_order_amount.present? && total < min_order_amount

    raw = percent? ? (total * discount_value / 100) : discount_value.to_d
    max_discount.present? ? [raw, max_discount.to_d].min : raw
  end
end
