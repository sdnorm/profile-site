require "test_helper"

class Studio::InquiryTest < ActiveSupport::TestCase
  def build(**attrs) = Studio::Inquiry.new({ email: "a@b.com", message: "We drown in PDFs." }.merge(attrs))

  test "valid with email and message" do
    assert build.valid?
  end

  test "interest defaults to not_sure" do
    assert_equal "not_sure", build.interest
  end

  test "invalid without email, with a malformed email, or without a message" do
    assert_not build(email: "").valid?
    assert_not build(email: "nope").valid?
    assert_not build(message: "").valid?
  end

  test "interest must be a known lane" do
    Studio::Inquiry::INTERESTS.each { |i| assert build(interest: i).valid?, i }
    assert_not build(interest: "crypto").valid?
  end

  test "interest_label is human readable" do
    assert_equal "Build", build(interest: "build").interest_label
    assert_equal "Signal Audit", build(interest: "audit").interest_label
    assert_equal "Not sure yet", build.interest_label
  end

  test "caps field lengths so oversized submissions are rejected" do
    assert_not build(name: "a" * 121).valid?
    assert_not build(company: "a" * 121).valid?
    assert_not build(message: "a" * 5001).valid?
    assert build(name: "a" * 120, company: "a" * 120, message: "a" * 5000).valid?
  end
end
