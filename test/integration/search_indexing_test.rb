require "test_helper"

class SearchIndexingTest < ActionDispatch::IntegrationTest
  STUDIO   = "https://www.normansimplified.com"
  PERSONAL = "https://spencernorman.io"

  test "studio pages declare a canonical URL on the www host" do
    host! "www.normansimplified.com"
    { "/" => "/", "/ai-integration" => "/ai-integration", "/how-we-work" => "/how-we-work", "/contact?lane=ai" => "/contact" }.each do |path, canonical|
      get path
      assert_select "link[rel=canonical]", count: 1 do |tags|
        assert_equal "#{STUDIO}#{canonical}", tags.first["href"], "canonical for #{path}"
      end
    end
  end

  test "personal home declares a canonical URL, including on fallback hosts" do
    [ "spencernorman.io", "localhost" ].each do |host|
      host! host
      get "/"
      assert_select "link[rel=canonical]", count: 1 do |tags|
        assert_equal "#{PERSONAL}/", tags.first["href"], "canonical on #{host}"
      end
    end
  end

  test "studio sitemap lists every studio page and nothing else" do
    host! "www.normansimplified.com"
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_equal [ "/", "/ai-integration", "/how-we-work", "/contact" ].map { |p| "#{STUDIO}#{p}" }, sitemap_locs
  end

  test "personal sitemap lists the personal home page" do
    host! "spencernorman.io"
    get "/sitemap.xml"
    assert_response :success
    assert_equal [ "#{PERSONAL}/" ], sitemap_locs
  end

  test "each site's robots.txt allows crawling and points at its own sitemap" do
    { "www.normansimplified.com" => STUDIO, "spencernorman.io" => PERSONAL }.each do |host, origin|
      host! host
      get "/robots.txt"
      assert_response :success
      assert_equal "text/plain", response.media_type
      assert_match(/^User-agent: \*$/, response.body)
      assert_match(/^Allow: \/$/, response.body)
      assert_no_match(/^Disallow: \/$/, response.body)
      assert_match(/^Sitemap: #{Regexp.escape(origin)}\/sitemap\.xml$/, response.body)
    end
  end

  test "non-canonical production hosts redirect permanently, keeping path and query" do
    host! "normansimplified.com"
    get "/contact?lane=ai"
    assert_response :moved_permanently
    assert_equal "#{STUDIO}/contact?lane=ai", response.location

    get "/sitemap.xml"
    assert_equal "#{STUDIO}/sitemap.xml", response.location

    host! "www.spencernorman.io"
    get "/"
    assert_response :moved_permanently
    assert_equal "#{PERSONAL}/", response.location
  end

  private

  def sitemap_locs
    Nokogiri::XML(response.body).remove_namespaces!.xpath("//url/loc").map(&:text)
  end
end
