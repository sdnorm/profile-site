class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  generates_token_for :qr_sign_in, expires_in: 15.minutes do
    password_salt&.last(8)
  end
end
