module Personal
  class BaseController < ApplicationController
    layout "personal"

    def current_site = :personal
    helper_method :current_site
  end
end
