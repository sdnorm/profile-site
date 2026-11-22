# Keeps the legacy demo and sign-in pages out of search results on both sites.
module Unindexed
  extend ActiveSupport::Concern

  included do
    before_action { response.headers["X-Robots-Tag"] = "noindex" }
  end
end
