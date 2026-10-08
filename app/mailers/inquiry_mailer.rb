class InquiryMailer < ApplicationMailer
  def new_inquiry(inquiry)
    @inquiry = inquiry
    sender_label = inquiry.name.presence || inquiry.email

    mail(
      to: Rails.application.credentials.dig(:contact, :recipient) || "spencernorman@hey.com",
      from: Rails.application.credentials.dig(:mailgun, :from).presence || "Norman Simplified <no-reply@spencernorman.io>",
      reply_to: inquiry.email,
      subject: "New Norman Simplified inquiry (#{inquiry.interest_label}) from #{sender_label}"
    )
  end
end
