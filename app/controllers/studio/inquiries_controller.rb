module Studio
  class InquiriesController < BaseController
    def new
      @inquiry = Inquiry.new(interest: requested_interest)
      @sent = flash[:inquiry_sent].present?
    end

    def create
      @inquiry = Inquiry.new(inquiry_params)

      if @inquiry.valid? && turnstile_verified?
        InquiryMailer.new_inquiry(@inquiry).deliver_now
        @sent = true
      end

      respond
    rescue => e
      Rails.logger.error("Inquiry delivery failed: #{e.class}: #{e.message}")
      @inquiry.errors.add(:base, "Couldn't send right now. Please try again in a moment.")
      respond
    end

    private

    def inquiry_params
      params.require(:studio_inquiry).permit(:name, :email, :company, :interest, :message)
    end

    def requested_interest
      Inquiry::INTERESTS.include?(params[:interest]) ? params[:interest] : "not_sure"
    end

    def turnstile_verified?
      verified = Turnstile::Verification.new(
        token: params["cf-turnstile-response"], remote_ip: request.remote_ip
      ).verified?
      @inquiry.errors.add(:base, "Please complete the verification and try again.") unless verified
      verified
    end

    def respond
      respond_to do |format|
        format.turbo_stream { render :create, status: (@sent ? :ok : :unprocessable_entity) }
        format.html do
          if @sent
            redirect_to studio_contact_path, status: :see_other, flash: { inquiry_sent: true }
          else
            render :new, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
