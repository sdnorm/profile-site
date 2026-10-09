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
    [ "/", "/ai-integration", "/how-we-work", "/contact" ].each do |path|
      get path
      assert_select "title", /Norman Simplified/
      assert_select "meta[name=description][content]"
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

    %w[Documents Answers Workflows Numbers].each do |group|
      assert_select "h2, h3", text: group
    end
    assert_select "[data-catalog-item]", count: 12
    assert_select "[data-controller=explorer]" do |explorer|
      assert_match(/sample|fictional/i, explorer.text)
    end
  end
end
