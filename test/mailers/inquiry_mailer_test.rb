require "test_helper"

class InquiryMailerTest < ActionMailer::TestCase
  test "new_inquiry builds the email" do
    inquiry = Studio::Inquiry.new(name: "Jane Doe", email: "jane@acme.com", company: "Acme Supply",
                                  interest: "build", message: "Our order intake is all PDFs.")
    mail = InquiryMailer.new_inquiry(inquiry)

    assert_equal [ "spencernorman@hey.com" ], mail.to
    assert_equal [ "jane@acme.com" ], mail.reply_to
    assert_equal "New Norman Simplified inquiry (Build) from Jane Doe", mail.subject
    assert_match "Acme Supply", mail.body.encoded
    assert_match "Our order intake is all PDFs.", mail.body.encoded
  end

  test "subject falls back to email when name is blank" do
    inquiry = Studio::Inquiry.new(email: "jane@acme.com", message: "Hi")
    assert_equal "New Norman Simplified inquiry (Not sure yet) from jane@acme.com",
                 InquiryMailer.new_inquiry(inquiry).subject
  end
end
