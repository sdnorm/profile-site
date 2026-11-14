module Studio
  class NotesController < BaseController
    def index
      @notes = Note.all
    end

    def show
      @note = Note.find(params[:slug])
      return head :not_found unless @note

      render @note.template
    end
  end
end
