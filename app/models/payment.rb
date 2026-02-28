class Payment < ApplicationRecord
  enum :payment_method, { card: 0, kakao: 1, naver: 2, toss: 3 }, default: :card, validate: true
  enum :payment_status, { pending: 0, success: 1, failed: 2, refunded: 3 }, default: :pending, validate: true

  belongs_to :booking
  belongs_to :user

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
