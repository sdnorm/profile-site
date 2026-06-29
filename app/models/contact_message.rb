class ContactMessage
  include ActiveModel::Model

  attr_accessor :name, :email, :message

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
end
