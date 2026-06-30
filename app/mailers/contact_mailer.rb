class ContactMailer < ApplicationMailer
  def new_message(contact_message)
    @contact_message = contact_message
    sender_label = contact_message.name.presence || contact_message.email

    mail(
      to: Rails.application.credentials.dig(:contact, :recipient) || "spencernorman@hey.com",
      from: Rails.application.credentials.dig(:mailgun, :from).presence || "Spencer Norman <no-reply@spencernorman.io>",
      reply_to: contact_message.email,
      subject: "New portfolio inquiry from #{sender_label}"
    )
  end
end
