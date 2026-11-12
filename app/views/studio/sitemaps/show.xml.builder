origin = { host: canonical_host, protocol: "https" }

xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [
    studio_root_url(**origin),
    studio_ai_integration_url(**origin),
    studio_how_we_work_url(**origin),
    studio_contact_url(**origin)
  ].each { |loc| xml.url { xml.loc loc } }
end
