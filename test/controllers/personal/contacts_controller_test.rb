require "test_helper"

class Personal::ContactsControllerTest < ActionDispatch::IntegrationTest
  setup { host! "spencernorman.io" }

  test "missing fields re-render the form (422) and send nothing" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post personal_contact_path,
        params: { contact_message: { name: "", email: "", message: "" } },
        as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_match "contact_panel", @response.body
  end

  test "a valid submission sends one email and renders success" do
    # Turnstile secret is blank in test, so Turnstile::Verification bypasses (no mock needed).
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post personal_contact_path,
        params: { contact_message: { name: "Jane", email: "jane@acme.com", message: "hello there" } },
        as: :turbo_stream
    end
    assert_response :success
    assert_match "Message sent", @response.body
  end
end
