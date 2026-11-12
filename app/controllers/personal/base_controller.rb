module Personal
  class BaseController < ApplicationController
    layout "personal"

    def current_site = :personal
    def canonical_host = "spencernorman.io"
    helper_method :current_site, :canonical_host
  end
end
