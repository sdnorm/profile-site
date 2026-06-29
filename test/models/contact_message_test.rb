require "test_helper"

class ContactMessageTest < ActiveSupport::TestCase
  test "valid with email and message" do
    assert ContactMessage.new(email: "a@b.com", message: "hi there").valid?
  end

  test "invalid without email" do
    assert_not ContactMessage.new(message: "hi there").valid?
  end

  test "invalid without message" do
    assert_not ContactMessage.new(email: "a@b.com").valid?
  end

  test "invalid with a malformed email" do
    assert_not ContactMessage.new(email: "nope", message: "hi there").valid?
  end
end
