module Personal
  class ContactsController < BaseController
    include TurnstileVerifiable

    def create
      @contact_message = ContactMessage.new(contact_params)
      @sent = @contact_message.valid? && turnstile_verified_for?(@contact_message) && deliver_message
      render_panel
    end

    private

    def contact_params
      params.fetch(:contact_message, {}).permit(:name, :email, :message)
    end

    def deliver_message
      ContactMailer.new_message(@contact_message).deliver_now
      true
    rescue => e
      Rails.logger.error("Contact delivery failed: #{e.class}: #{e.message}")
      @contact_message.errors.add(:base, "Couldn't send right now — please try again in a moment.")
      false
    end

    def render_panel
      respond_to do |format|
        format.turbo_stream { render status: (@sent ? :ok : :unprocessable_entity) }
        format.html { redirect_to root_path(anchor: "contact") }
      end
    end
  end
end
