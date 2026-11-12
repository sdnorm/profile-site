xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url { xml.loc personal_root_url(host: canonical_host, protocol: "https") }
end
