require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  setup do
    @original_token = Rails.configuration.x.posthog.token
    @original_host = Rails.configuration.x.posthog.host
    Rails.configuration.x.posthog.token = nil
    Rails.configuration.x.posthog.host = "https://us.i.posthog.com"
  end

  teardown do
    Rails.configuration.x.posthog.token = @original_token
    Rails.configuration.x.posthog.host = @original_host
  end

  test "a blank token renders no PostHog on either site" do
    [ "spencernorman.io", "www.normansimplified.com" ].each do |host|
      host! host
      get "/"
      assert_response :success
      assert_no_match(/posthog/i, response.body)
    end
  end

  test "both sites initialize cookieless analytics with their site property" do
    Rails.configuration.x.posthog.token = "phc_test"
    { "spencernorman.io" => "personal", "www.normansimplified.com" => "studio" }.each do |host, site|
      host! host
      get "/"
      assert_select "head script#site-analytics", count: 1 do |scripts|
        script = scripts.first.text
        assert_includes script, 'posthog.init("phc_test"'
        assert_includes script, 'api_host: "https://us.i.posthog.com"'
        assert_includes script, "defaults: '2026-05-30'"
        assert_includes script, "cookieless_mode: 'always'"
        assert_includes script, "autocapture: false"
        assert_includes script, "disable_session_recording: true"
        assert_includes script, "capture_pageleave: true"
        assert_includes script, "posthog.register({ site: #{site.to_json} })"
      end
    end
  end

  test "contact CTAs declare only fixed event properties" do
    host! "spencernorman.io"
    get "/"
    assert_select "button[type=submit][data-action*='analytics#track'][data-analytics-cta-param=send_message]"
    assert_select "a[href='#contact']", minimum: 2 do |links|
      links.each do |link|
        assert_includes link["data-action"].to_s, "analytics#track"
        assert_equal "cta_clicked", link["data-analytics-event-param"]
        assert_equal "get_in_touch", link["data-analytics-cta-param"]
      end
    end

    host! "www.normansimplified.com"
    [ "/", "/ai-integration", "/how-we-work", "/contact" ].each do |path|
      get path
      assert_select "a[href^='/contact']", minimum: 1 do |links|
        links.each do |link|
          assert_includes link["data-action"].to_s, "analytics#track", "untracked CTA on #{path}"
          assert_equal "cta_clicked", link["data-analytics-event-param"]
          assert_equal "request_a_call", link["data-analytics-cta-param"]
          assert link["data-analytics-location-param"].present?
          interest = Rack::Utils.parse_query(URI.parse(link["href"]).query)["interest"]
          assert_equal interest, link["data-analytics-interest-param"] if interest
        end
      end
    end
    assert_select "button[type=submit][data-action*='analytics#track'][data-analytics-cta-param=request_a_call]"
  end

  test "studio conversion contains only the validated raw interest after success" do
    host! "www.normansimplified.com"
    post "/contact", params: { studio_inquiry: { name: "Private Name", email: "private@example.test", company: "Private Company", message: "Private message", interest: "build" } }, as: :turbo_stream
    assert_response :success
    assert_select "[data-analytics-on-connect-value=inquiry_submitted]", count: 1 do |panels|
      assert_equal({ "interest" => "build" }, JSON.parse(panels.first["data-analytics-properties-value"]))
    end
    assert_no_match(/Private|private@example/, response.body)

    post "/contact", params: { studio_inquiry: { email: "bad", message: "" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_select "[data-analytics-on-connect-value]", count: 0
  end

  test "studio HTML redirect success reports unknown interest" do
    host! "www.normansimplified.com"
    post "/contact", params: { studio_inquiry: { email: "private@example.test", message: "Private message", interest: "automate" } }
    assert_response :see_other
    follow_redirect!
    assert_select "[data-analytics-on-connect-value=inquiry_submitted]", count: 1 do |panels|
      assert_equal({ "interest" => "unknown" }, JSON.parse(panels.first["data-analytics-properties-value"]))
    end
  end

  test "personal conversion renders only after a successful submission" do
    host! "spencernorman.io"
    post personal_contact_path, params: { contact_message: { name: "Private Name", email: "private@example.test", message: "Private message" } }, as: :turbo_stream
    assert_response :success
    assert_select "[data-analytics-on-connect-value=contact_submitted]", count: 1
    assert_no_match(/Private|private@example/, response.body)

    post personal_contact_path, params: { contact_message: { email: "bad", message: "" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_select "[data-analytics-on-connect-value]", count: 0
  end
end
