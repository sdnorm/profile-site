module Studio
  class NotesController < BaseController
    def index
      @notes = Note.all
    end

    def show
      @note = Note.find(params[:slug])
      raise ActionController::RoutingError, "Not Found" unless @note

      render @note.template
    end
  end
end
