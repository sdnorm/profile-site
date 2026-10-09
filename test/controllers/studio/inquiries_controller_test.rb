require "test_helper"

class Studio::InquiriesControllerTest < ActionDispatch::IntegrationTest
  setup { host! "normansimplified.com" }

  def valid_params = { studio_inquiry: { name: "Jane", email: "jane@acme.com", interest: "automate", message: "Invoices by hand." } }

  test "new renders the form with interest preselected from the query" do
    get studio_contact_path(interest: "build")
    assert_response :success
    assert_select "body[data-site=studio]"
    assert_select "select[name='studio_inquiry[interest]'] option[selected][value=build]"
  end

  test "new ignores an unknown interest" do
    get studio_contact_path(interest: "crypto")
    assert_response :success
    assert_select "select[name='studio_inquiry[interest]'] option[selected][value=not_sure]"
  end

  test "valid turbo submission sends one email and renders success" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post studio_contact_path, params: valid_params, as: :turbo_stream
    end
    assert_response :success
    assert_match "inquiry_panel", @response.body
    assert_match "Request received", @response.body
    assert_match "(Automate)", ActionMailer::Base.deliveries.last.subject
  end

  test "invalid turbo submission re-renders the form (422) and sends nothing" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post studio_contact_path, params: { studio_inquiry: { email: "", message: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_match "inquiry_panel", @response.body
  end

  test "html fallback: success redirects with 303, errors re-render with 422" do
    post studio_contact_path, params: valid_params
    assert_response :see_other
    assert_redirected_to studio_contact_path
    follow_redirect!
    assert_match "Request received", @response.body

    post studio_contact_path, params: { studio_inquiry: { email: "nope", message: "" } }
    assert_response :unprocessable_entity
    assert_select "form[action='#{studio_contact_path}']"
  end

  test "a post without inquiry params re-renders the form instead of erroring" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post studio_contact_path, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_match "inquiry_panel", @response.body
  end

  test "a delivery failure shows the friendly error once and records no delivery" do
    ActionMailer::Base.register_interceptor(FailingDelivery)
    post studio_contact_path, params: valid_params, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_match "It did not send", @response.body
    assert_empty ActionMailer::Base.deliveries
  ensure
    ActionMailer::Base.unregister_interceptor(FailingDelivery)
  end
end
