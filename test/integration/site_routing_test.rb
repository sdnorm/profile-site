require "test_helper"

class SiteRoutingTest < ActionDispatch::IntegrationTest
  test "personal host root renders the personal layout" do
    host! "spencernorman.io"
    get "/"
    assert_response :success
    assert_select "body[data-site=personal]"
  end

  test "personal localhost subdomain renders the personal layout" do
    host! "spencernorman.localhost"
    get "/"
    assert_response :success
    assert_select "body[data-site=personal]"
  end

  test "studio host root renders the studio layout" do
    host! "normansimplified.com"
    get "/"
    assert_response :success
    assert_select "body[data-site=studio]"
  end

  test "studio localhost subdomain renders the studio layout" do
    host! "normansimplified.localhost"
    get "/"
    assert_response :success
    assert_select "body[data-site=studio]"
  end
end
