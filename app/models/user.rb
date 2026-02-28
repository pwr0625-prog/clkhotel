require "openssl"
require "securerandom"

class User < ApplicationRecord
  ITERATIONS = 210_000
  KEY_LENGTH = 32

  enum :user_type, { guest: 0, host: 1, admin: 2 }, default: :guest, validate: true

  has_many :properties, foreign_key: :host_id, inverse_of: :host, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_many :wishlist_properties, through: :wishlists, source: :property

  attr_accessor :password, :password_confirmation

  before_validation :normalize_email
  before_validation :hash_password, if: :password_present?

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create
  validates :password, length: { minimum: 8 }, if: :password_present?
  validates :password, confirmation: true, if: :password_present?

  def authenticate(raw_password)
    return false if raw_password.blank? || password_hash.blank? || password_salt.blank?

    candidate = self.class.digest(raw_password, password_salt)
    ActiveSupport::SecurityUtils.secure_compare(password_hash, candidate) ? self : false
  end

  def self.digest(raw_password, salt)
    OpenSSL::KDF.pbkdf2_hmac(
      raw_password,
      salt: salt,
      iterations: ITERATIONS,
      length: KEY_LENGTH,
      hash: "sha256"
    ).unpack1("H*")
  end

  def role_label
    { "guest" => "게스트", "host" => "호스트", "admin" => "관리자" }.fetch(user_type, user_type)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_present?
    password.present?
  end

  def hash_password
    self.password_salt = SecureRandom.hex(16)
    self.password_hash = self.class.digest(password, password_salt)
  end
end
