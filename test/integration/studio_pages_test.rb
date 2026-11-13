require "test_helper"

class StudioPagesTest < ActionDispatch::IntegrationTest
  setup { host! "www.normansimplified.com" }

  test "studio pages render in the studio layout" do
    [ "/", "/ai-integration", "/how-we-work" ].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
      assert_select "body[data-site=studio]"
    end
  end

  test "every studio page has a title, meta description, and a Request a call link" do
    descriptions = {
      "/" => "Reduce repetitive paperwork and data entry. Work directly with Spencer Norman, starting with a two-week Workflow Review for $4,500.",
      "/ai-integration" => "Examples of document and workflow automation after a Workflow Review. See a sample, possible projects, and how we agree what to measure.",
      "/how-we-work" => "Start with a two-week Workflow Review for $4,500. See what is included, implementation prices, and what happens next.",
      "/contact" => "Tell Spencer where paperwork or repeated data entry slows your team down. He replies by email within two business days to discuss a 25-minute call."
    }
    descriptions.each do |path, description|
      get path
      assert_select "title", /Norman Simplified/
      assert_select "meta[name=description]", count: 1 do |tags|
        assert_equal description, tags.first["content"], "description for #{path}"
      end
      assert_select "h1", count: 1
      assert_select "a[href^='/contact']", minimum: 1
    end
  end

  test "nav links to the review and every page" do
    get "/"
    assert_select "nav a[href='/#review']", text: "Workflow Review"
    assert_select "nav a[href='/ai-integration']"
    assert_select "nav a[href='/how-we-work']"
    assert_select "nav a[href^='/contact']", text: /Request a call/
  end

  test "home leads with the outcome, the Workflow Review price, and one call to action" do
    get "/"
    assert_select "h1", "Less retyping. Less chasing paperwork."
    assert_select ".ns-hero" do
      assert_select "*", text: /Workflow Review for \$4,500/
      assert_select "a[href='/contact?interest=audit']", text: "Request a call", count: 1
    end
    assert_select "#review", text: /\$4,500 fixed fee\. Two weeks\./
    assert_select "#review", text: /\$2,000 of the fee is credited/
    assert_select "#services [data-lane]", 3
    [ "$3,500", "$7,500", "$18,000" ].each { |price| assert_match price, @response.body }
    %w[adopt automate build].each { |lane| assert_select "#services a[href='/how-we-work##{lane}']" }
  end

  test "retired names, exclusions and unbacked claims are gone from every page" do
    retired = /Signal Audit|Flow Care|Desk Hours|Managed AI Ops|Fractional|Legacy Rescue|Flexfit|PHI\b|BAA\b|healthcare|Technology, simplified/i
    [ "/", "/ai-integration", "/how-we-work", "/contact" ].each do |path|
      get path
      text = Nokogiri::HTML(@response.body).at("body").text
      assert_no_match retired, text, "retired wording on #{path}"
      assert_no_match retired, Nokogiri::HTML(@response.body).at("title").text
    end
  end

  test "how we work shows the fixed prices and the Workflow Review" do
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
    assert_select "details summary h3", count: 5
    assert_select "details[open]", count: 0
    assert_no_match(/\$(12|28|38|42),000/, @response.body)
    assert_select "[data-catalog-item] a[href^='/contact?']", count: 12
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
