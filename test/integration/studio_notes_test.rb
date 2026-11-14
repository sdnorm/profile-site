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
    ([ "/notes" ] + Studio::Note.all.map { |note| "/notes/#{note.slug}" }).each do |note_path|
      get note_path
      claimed = css_select("main section").select { |section| section.text.match?(/your own server|a server you own|you own|you control|your server/i) }
      claimed.each { |section| assert_includes section.text, SENTENCE, "#{note_path} #{section['id']}" }
    end
    get "/notes/your-server-or-the-vendors"
    assert css_select("main section").any? { |section| section.text.match?(/a server you own|you own/i) }
  end

  test "the first article covers accounts, the model, storage and four questions" do
    get "/notes/what-leaves-your-business"
    assert_select "#pasted", text: /personal account belongs to the person who signed up/
    assert_select "#pasted", text: /business account is opened in the company's name/
    assert_select "#agent-sends", text: /the text it is working on is sent to the model provider/
    assert_select "#stays-put", text: /record of each run/
    assert_select "#questions ol li", 4
    [ /business account in my company's name/, /used to train the model/, /How long is the text kept/, /read the record of what was sent/ ].each_with_index do |phrase, i|
      assert_select "#questions ol li:nth-child(#{i + 1})", text: phrase
    end
    assert_select "#questions", text: /I do not quote any vendor's terms/
  end

  test "the second article covers both places, three reasons, upkeep and the pilot path" do
    get "/notes/your-server-or-the-vendors"
    assert_select "#two-places", text: /hosted service/
    assert_select "#hosted", text: /Ask what is backed up/
    assert_no_match(/nothing to back up/, @response.body)
    assert_select "#reasons ul li", 3
    [ /asks you to say where the data is stored/, /credentials you want kept on a machine/, /keep running whoever you work with/ ].each_with_index do |phrase, i|
      assert_select "#reasons ul li:nth-child(#{i + 1})", text: phrase
    end
    assert_select "#upkeep", text: /updates, backups and someone watching it/
    assert_select "#upkeep", text: /ongoing support/
    assert_select "#decide", text: /A pilot can start on the hosted service and move to a server later/
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
