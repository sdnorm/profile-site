require "test_helper"

class StudioPagesTest < ActionDispatch::IntegrationTest
  setup { host! "normansimplified.com" }

  test "studio pages render in the studio layout" do
    [ "/", "/ai-integration", "/how-we-work" ].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
      assert_select "body[data-site=studio]"
    end
  end

  test "every studio page has a title, meta description, and a Request a call link" do
    descriptions = {
      "/" => "AI tools, automations, and custom software for operators buried in documents, spreadsheets, and aging tools. You work directly with Spencer Norman.",
      "/ai-integration" => "Document intake, answers from your own files, and workflow automation inside the systems you already use. Human review, a measured sample, and a plain account of running cost.",
      "/how-we-work" => "Fixed prices for Pick ($3,500) and Rollout ($8,500). Automate from $7,500. Build from $18,000. A Signal Audit is $4,500 if the workflow is still unclear.",
      "/contact" => "Tell Spencer the workflow that is stuck. He replies by email within two business days. This form does not reserve a time."
    }
    descriptions.each do |path, description|
      get path
      assert_select "title", /Norman Simplified/
      assert_select "meta[name=description]", count: 1 do |tags|
        assert_equal description, tags.first["content"], "description for #{path}"
      end
      assert_select "a[href^='/contact']", minimum: 1
    end
  end

  test "nav links to every v1 page" do
    get "/"
    assert_select "nav a[href='/ai-integration']"
    assert_select "nav a[href='/how-we-work']"
    assert_select "nav a[href^='/contact']", text: /Request a call/
  end

  test "home shows the brand line, three lanes with starting prices, and lane CTAs" do
    get "/"
    assert_select "h1", /Technology, simplified/
    assert_select "#services [data-lane]", 3
    [ "$3,500", "$7,500", "$18,000" ].each { |price| assert_match price, @response.body }
    %w[adopt automate build].each { |lane| assert_select "a[href='/contact?interest=#{lane}']" }
    assert_select "details", minimum: 6
  end

  test "how we work shows exact Adopt prices and the Signal Audit" do
    get "/how-we-work"
    [ "$3,500", "$8,500", "$4,500" ].each { |price| assert_match price, @response.body }
    assert_select "a[href='/contact?interest=audit']"
    assert_no_match(/per hour|\/hr/i, @response.body)
  end

  test "AI integration groups twelve builds and labels its recorded explorer" do
    get "/ai-integration"

    [ "Documents", "Answers", "Workflows", "Numbers", "Sales and support" ].each do |group|
      assert_select "h2, h3", text: group
    end
    assert_select "[data-catalog-item]", count: 12
    assert_select "[data-controller=explorer]" do |explorer|
      assert_match(/sample|fictional/i, explorer.text)
      assert_select "[data-explorer-target=status]", text: "Step 1 of 4 — Document"
    end
    assert_select "details[open] summary h3", count: 5
  end

  test "only the contact page loads Turnstile" do
    [ "/", "/ai-integration", "/how-we-work", "/contact" ].each do |path|
      get path
      assert_select "head script[src*='challenges.cloudflare.com/turnstile']", count: (path == "/contact" ? 1 : 0)
    end
  end

  test "contact fields expose limits without stealing focus on first load" do
    get "/contact"
    assert_select "input[name='studio_inquiry[name]'][maxlength='120']"
    assert_select "input[name='studio_inquiry[company]'][maxlength='120']"
    assert_select "textarea[name='studio_inquiry[message]'][maxlength='5000']"
    assert_select "#inquiry_panel [autofocus]", count: 0
  end

  test "invalid Turbo inquiries announce field errors and focus email before message" do
    [ [ "not-an-email", "email" ], [ "jane@example.test", "message" ] ].each do |email, focused_field|
      post "/contact", params: { studio_inquiry: { email: email, message: "" } }, as: :turbo_stream
      assert_response :unprocessable_entity
      assert_select "turbo-stream[target=inquiry_panel] template" do
        assert_select "[autofocus]", count: 1
        assert_select "[name='studio_inquiry[#{focused_field}]'][autofocus][aria-invalid=true]"
        assert_select "[role=alert] a[href='#studio_inquiry_message']", text: /Add this/
        if focused_field == "email"
          assert_select "[role=alert] a[href='#studio_inquiry_email']", text: /does not look usable/
        end
      end
    end
  end
end
