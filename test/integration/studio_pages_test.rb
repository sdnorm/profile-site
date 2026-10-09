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
end
