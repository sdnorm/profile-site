module Studio
  class BaseController < ApplicationController
    layout "studio"

    def current_site = :studio
    def canonical_host = "www.normansimplified.com"
    helper_method :current_site, :canonical_host
  end
end
