require "test_helper"

class StudioPagesTest < ActionDispatch::IntegrationTest
  setup { host! "www.normansimplified.com" }

  test "studio pages render in the studio layout" do
    STUDIO_PATHS.each do |path|
      get path
      assert_response :success, "expected #{path} to render"
      assert_select "body[data-site=studio]"
    end
  end

  test "every studio page has a title, meta description, and a Request a call link" do
    descriptions = {
      "/" => "Put AI agents to work on one recurring job, with limits you set and a person approving what goes out. Pilots are $9,500 fixed fee with Spencer Norman.",
      "/agent-readiness-review" => "A one-week Agent Readiness Review for $3,500. Find out which job an AI agent should take first, what it would be allowed to do, and what it costs.",
      "/where-agents-run" => "Your own server or the vendor's hosted service: what is stored where, what is sent to the AI model, and what it takes to keep running.",
      "/ai-integration" => "Examples of jobs an AI agent can take on, with a person approving the exceptions. See a sample, possible projects, and how we agree what to measure.",
      "/how-we-work" => "A pilot on one job is $9,500 fixed fee. Not sure where to start? The Agent Readiness Review is $3,500. See what each includes and what follows.",
      "/contact" => "Tell Spencer which job you want off someone's desk. He replies by email within two business days to discuss a 25-minute call."
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

  test "review page states the offer, the fit, and how the week runs" do
    get "/agent-readiness-review"
    assert_response :success
    assert_select "h1", "Agent Readiness Review"
    assert_match "$3,500 fixed fee. One week.", @response.body
    assert_match "The full $3,500 is credited toward a pilot that starts within 60 days.", @response.body
    assert_select "dl.ns-review__outline > div", 7
    assert_select "h2", text: "A good fit if"
    assert_select "h2", text: "Probably not a fit if"
    assert_match(/no passwords/i, @response.body)
    assert_match "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.", @response.body
    assert_select "#report-outline", text: /This is not offline\. When the agent uses the AI model, the text it is working on is sent to the model provider\./
    assert_select "section[aria-labelledby=notfit-title]" do
      assert_select "li", text: /no outside connection at all/
      assert_select "li", text: /chatbot for a public website/
      assert_select "li", text: /procurement process/
      assert_select "li", text: /few times a year/
    end
    assert_select "a[href='/contact?interest=audit']", text: "Request a call", minimum: 1
  end

  test "nav and footer link to the offer and every page" do
    get "/"
    assert_select "nav[aria-label=Primary] a[href='/#review']", text: "How a pilot works"
    assert_select "nav[aria-label=Primary] a[href='/ai-integration']", text: "Examples"
    assert_select "nav[aria-label=Primary] a[href='/how-we-work']"
    assert_select "nav[aria-label=Primary] a[href^='/contact']", text: /Request a call/
    assert_select "nav[aria-label=Footer] a[href='/agent-readiness-review']"
    assert_select ".ns-footer__tagline", "Put AI agents to work. Keep control of what they can do."
  end

  test "home leads with the pilot, states the limits, and offers the review second" do
    get "/"
    assert_select "h1", "Put AI agents to work. Keep control of what they can do."
    assert_select ".ns-hero" do
      assert_select "*", text: /\$9,500/
      assert_select "a[href='/contact?interest=pilot']", text: "Request a call", count: 1
    end
    assert_select "#review", text: /\$9,500 fixed fee\. Three to four weeks\./
    assert_select "#review", text: /\$3,500 fixed fee\. One week\./
    assert_select "#review a[href='/agent-readiness-review']"
    assert_select "#control", text: /This is not offline\. When the agent uses the AI model, the text it is working on is sent to the model provider\./
    assert_select "#control li, #control dt", minimum: 7
    assert_select "#services [data-lane]", 3
    assert_select "#services", text: /This is not offline\. When the agent uses the AI model, the text it is working on is sent to the model provider\./
    %w[agents setup support].each { |lane| assert_select "#services [data-lane=#{lane}] a[href='/how-we-work##{lane}']" }
    [ "$18,000", "$6,500", "$750" ].each { |price| assert_match price, @response.body }
    assert_select "#about", text: /Implementation example/
    [ "Is our data sent anywhere?", "Do we need technical staff?", "What if the agent gets something wrong?", "What if we stop working with you?", "Who owns the work when it is done?" ].each do |question|
      assert_select "#faq summary", text: question
    end
  end

  test "retired names, exclusions and unbacked claims are gone from every page" do
    retired = /Signal Audit|Flow Care|Desk Hours|Managed AI Ops|Fractional|Legacy Rescue|Flexfit|PHI\b|BAA\b|healthcare|Technology, simplified|Workflow Review|\$4,500|\$5,500|\$15,000|never leaves|revolutionary|transformative|private beta/i
    STUDIO_PATHS.each do |path|
      get path
      text = Nokogiri::HTML(@response.body).at("body").text
      assert_no_match retired, text, "retired wording on #{path}"
      assert_no_match retired, Nokogiri::HTML(@response.body).at("title").text
    end
  end

  test "how we work leads with the pilot and keeps the other work below" do
    get "/how-we-work"
    assert_select "h1", "Start with one job"
    %w[pilot review-offer agents setup support other adopt automate build].each { |id| assert_select "##{id}", 1 }
    assert_select "#pilot", text: /\$9,500 fixed fee\. Three to four weeks\./
    assert_select "#review-offer", text: /\$3,500 fixed fee\. One week\./
    assert_select "#review-offer", text: /The full \$3,500 is credited toward a pilot that starts within 60 days\./
    assert_select "#review-offer a[href='/agent-readiness-review']"
    assert_select "#agents", text: /Starts at \$18,000/
    assert_select "#setup", text: /Starts at \$6,500/
    assert_select "#setup", text: /This is not offline\. When the agent uses the AI model, the text it is working on is sent to the model provider\./
    assert_select "#setup", text: /sign-in/
    assert_select "#setup", text: /firewall/
    assert_select "#setup", text: /encrypted backups/
    assert_select "#setup", text: /monitoring/
    assert_select "#setup", text: /handoff/
    assert_select "#support", text: /\$750 a month/
    assert_select "#support", text: /\$1,500 a month/
    assert_select "#support", text: /three-month minimum/i
    { "pilot" => "pilot", "review-offer" => "audit", "agents" => "agents", "setup" => "setup", "support" => "support" }.each do |id, interest|
      assert_select "##{id} a[href='/contact?interest=#{interest}']"
    end
    assert_select "#other ~ #adopt"
    assert_select "#build", text: /First version/
    %w[adopt automate build].each { |id| assert_select "##{id}", text: /Pilot/, count: 0 }
    assert_no_match(/Workflow Review|\$4,500|\$5,500|\$15,000/, Nokogiri::HTML(@response.body).at("main").text)
    assert_no_match(/Pilot<\/h3>\s*<p class="ns-how__price">Starts at \$18,000/, @response.body)
    assert_no_match(/per hour|\/hr/i, @response.body)
  end

  test "contact page talks about the job and the pilot" do
    get "/contact"
    assert_select "aside", text: /A pilot on one job is \$9,500 fixed fee/
    assert_select "select option[value=pilot]", text: "Pilot"
  end

  test "examples page presents its examples as jobs for an agent" do
    get "/ai-integration"
    assert_select ".ns-hero a[href='/contact?interest=pilot']", text: "Request a call"
    assert_match "A pilot on one job is $9,500 fixed fee", @response.body
    assert_no_match(/Pilot starts at \$18,000/, @response.body)
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

  test "explainer compares the two places an agent can run and says what is sent out" do
    get "/where-agents-run"
    assert_response :success
    assert_select "h1", "Where your agent runs"
    assert_select "h2", text: "On the vendor's hosted service"
    assert_select "h2", text: "On a server you own"
    assert_select "h2", text: "What is sent to the AI model"
    assert_select "h2", text: "What it takes to keep a server running"
    assert_select "[data-diagram=where-agents-run]", 1
    assert_select "img", 0
    assert_match "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.", @response.body
    assert_no_match(/sandbox|inference|control plane/i, Nokogiri::HTML(@response.body).at("main").text)
    assert_select "a[href='/contact?interest=pilot']", minimum: 1
    get "/"
    assert_select "#control a[href='/where-agents-run']"
  end

  test "explainer sections that mention a server you own repeat the model sentence" do
    get "/where-agents-run"
    assert_response :success
    assert_select "title", "Where your AI agent runs | Norman Simplified"
    sentence = "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider."
    claimed = css_select("main section").select { |section| section.text.match?(/your own server|a server you own|you own|you control/i) }
    assert claimed.any?
    claimed.each { |section| assert_includes section.text, sentence, section["id"].to_s }

    assert_select "#vendor", text: /the agent, its files, its credentials and the record of each run/
    assert_select "#vendor", text: /your business account/
    assert_select "#vendor", text: /I hold nothing you cannot revoke/
    assert_select "#own-server", text: /the agent, its files, its credentials and the record of each run/
    assert_select "#own-server", text: /your own hosting account/
    assert_select "#own-server", text: /sometimes called a VPS/
    assert_select "#sent", text: /true on the vendor's hosted service and on a server you own/
    assert_select "#sign-in li", text: /firewall/i
    assert_select "#sign-in li", text: /who can sign in/i
    assert_select "#sign-in li", text: /encrypted backups/i
    assert_select "#sign-in li", text: /credentials limited to what the job needs/i
    assert_select "#down", text: /waits in a queue/
    assert_select "#down", text: /the old way/
    assert_select "#down", text: /Nothing the business depends on stops/
    assert_select "#running", text: /updates, backups and monitoring/
    assert_select "#running a[href='/how-we-work#support']"
  end

  test "only the contact page loads Turnstile" do
    STUDIO_PATHS.each do |path|
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
