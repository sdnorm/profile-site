# Serves a per-site robots.txt that points crawlers at that site's sitemap.
# The including controller supplies `canonical_host`.
module RobotsFile
  def show
    render plain: <<~ROBOTS
      User-agent: *
      Allow: /

      Sitemap: https://#{canonical_host}/sitemap.xml
    ROBOTS
  end
end
