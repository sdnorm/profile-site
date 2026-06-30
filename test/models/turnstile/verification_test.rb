require "test_helper"

class Turnstile::VerificationTest < ActiveSupport::TestCase
  test "bypasses (returns true) when secret is blank" do
    assert Turnstile::Verification.new(token: "any-token", secret: "").verified?
  end

  test "returns false for a blank token when a secret is present" do
    assert_not Turnstile::Verification.new(token: "", secret: "a-secret").verified?
  end

  test "returns true when Cloudflare reports success" do
    verification = Turnstile::Verification.new(token: "t", secret: "a-secret")
    verification.http = ->(**) { { "success" => true } }
    assert verification.verified?
  end

  test "returns false when Cloudflare reports failure" do
    verification = Turnstile::Verification.new(token: "t", secret: "a-secret")
    verification.http = ->(**) { { "success" => false } }
    assert_not verification.verified?
  end

  test "fails closed when the request raises" do
    verification = Turnstile::Verification.new(token: "t", secret: "a-secret")
    verification.http = ->(**) { raise "boom" }
    assert_not verification.verified?
  end
end
