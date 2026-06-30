require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "new_message builds the inquiry email" do
    cm = ContactMessage.new(name: "Jane Doe", email: "jane@acme.com", message: "We have a billing problem.")
    mail = ContactMailer.new_message(cm)

    assert_equal ["spencernorman@hey.com"], mail.to
    assert_equal ["jane@acme.com"], mail.reply_to
    assert_match "Jane Doe", mail.subject
    assert_match "We have a billing problem.", mail.body.encoded
  end

  test "subject falls back to email when name is blank" do
    cm = ContactMessage.new(email: "jane@acme.com", message: "Hi")
    assert_match "jane@acme.com", ContactMailer.new_message(cm).subject
  end
end
