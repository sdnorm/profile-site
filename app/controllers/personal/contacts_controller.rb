module Personal
  class ContactsController < BaseController
    def create
      @contact_message = ContactMessage.new(contact_params)

      if @contact_message.valid? && turnstile_verified?
        ContactMailer.new_message(@contact_message).deliver_now
        @sent = true
      end

      render_panel
    rescue => e
      Rails.logger.error("Contact delivery failed: #{e.class}: #{e.message}")
      @contact_message.errors.add(:base, "Couldn't send right now — please try again in a moment.")
      render_panel
    end

    private

    def contact_params
      params.require(:contact_message).permit(:name, :email, :message)
    end

    def turnstile_verified?
      verified = Turnstile::Verification.new(
        token: params["cf-turnstile-response"], remote_ip: request.remote_ip
      ).verified?
      @contact_message.errors.add(:base, "Please complete the verification and try again.") unless verified
      verified
    end

    def render_panel
      respond_to do |format|
        format.turbo_stream { render status: (@sent ? :ok : :unprocessable_entity) }
        format.html { redirect_to root_path(anchor: "contact") }
      end
    end
  end
end
