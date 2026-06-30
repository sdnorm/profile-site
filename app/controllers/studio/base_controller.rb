module Studio
  class BaseController < ApplicationController
    layout "studio"

    def current_site = :studio
    helper_method :current_site
  end
end
