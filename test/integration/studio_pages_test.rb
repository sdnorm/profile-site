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
end
