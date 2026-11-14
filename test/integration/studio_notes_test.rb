require "test_helper"

class StudioNotesTest < ActionDispatch::IntegrationTest
  SENTENCE = "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider."

  setup { host! "www.normansimplified.com" }

  test "index lists every note" do
    get "/notes"
    assert_select "h1", "Notes"
    assert_select "title", "Notes | Norman Simplified"
    assert_select "meta[name=description][content=?]", "Plain explanations of how AI agents handle your business data, from Spencer Norman."
    assert_select "a[href='/contact?interest=pilot']", text: "Request a call", minimum: 1
    Studio::Note.all.each { |note| assert_select "a[href='/notes/#{note.slug}']", text: note.title }
  end

  test "each note renders with its title, description and guardrails" do
    Studio::Note.all.each do |note|
      get "/notes/#{note.slug}"
      assert_response :success
      assert_select "h1", note.title
      assert_select "title", "#{note.title} | Norman Simplified"
      assert_select "meta[name=description][content=?]", note.description
      assert_match SENTENCE, @response.body
      assert_select "a[href='/where-agents-run']", minimum: 1
      assert_select "a[href='/contact?interest=pilot']", text: "Request a call", minimum: 1
      main = Nokogiri::HTML(@response.body).at("main").text
      assert_no_match(/\d+%|testimonial|never leaves|revolutionary|transformative/i, main)
      assert_no_match(/sandbox|inference|control plane|—/i, main)
      assert_includes (500..800), main.split.size, "#{note.slug} word count"
    end
  end

  test "every section that claims ownership repeats the model sentence" do
    Studio::Note.all.each do |note|
      get "/notes/#{note.slug}"
      claimed = css_select("main section").select { |section| section.text.match?(/your own server|a server you own|you own|you control|your server/i) }
      claimed.each { |section| assert_includes section.text, SENTENCE, "#{note.slug} #{section['id']}" }
    end
    get "/notes/your-server-or-the-vendors"
    assert css_select("main section").any? { |section| section.text.match?(/a server you own|you own/i) }
  end

  test "notes pages do not load the Turnstile script" do
    Studio::Note.all.each do |note|
      get "/notes/#{note.slug}"
      assert_select "script[src*='challenges.cloudflare.com']", count: 0
    end
  end

  test "unknown and hostile slugs are not found" do
    [ "/notes/nope", "/notes/..%2F..%2Flayouts%2Fstudio", "/notes/index" ].each do |path|
      get path
      assert_response :not_found, path
    end
  end
end
