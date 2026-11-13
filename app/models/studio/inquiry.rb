module Studio
  # A "Request a call" submission from normansimplified.com. Tableless: it is emailed, not stored.
  class Inquiry
    include ActiveModel::Model
    include ActiveModel::Attributes

    INTEREST_LABELS = {
      "adopt" => "Tools and training",
      "automate" => "Workflow automation",
      "build" => "Custom software",
      "audit" => "Workflow Review",
      "not_sure" => "Not sure yet"
    }.freeze
    INTERESTS = INTEREST_LABELS.keys.freeze

    attribute :name, :string
    attribute :email, :string
    attribute :company, :string
    attribute :interest, :string, default: "not_sure"
    attribute :message, :string

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :message, presence: true, length: { maximum: 5000 }
    validates :name, :company, length: { maximum: 120 }
    validates :interest, inclusion: { in: INTERESTS }

    def interest_label = INTEREST_LABELS.fetch(interest, interest.to_s.humanize)
  end
end
