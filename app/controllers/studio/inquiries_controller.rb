module Studio
  class InquiriesController < BaseController
    include TurnstileVerifiable

    def new
      @inquiry = Inquiry.new(interest: requested_interest)
      @sent = flash[:inquiry_sent].present?
    end

    def create
      @inquiry = Inquiry.new(inquiry_params)
      @sent = @inquiry.valid? && turnstile_verified_for?(@inquiry) && deliver_inquiry
      respond
    end

    private

    def inquiry_params
      params.fetch(:studio_inquiry, {}).permit(:name, :email, :company, :interest, :message)
    end

    def requested_interest
      Inquiry::INTERESTS.include?(params[:interest]) ? params[:interest] : "not_sure"
    end

    def deliver_inquiry
      InquiryMailer.new_inquiry(@inquiry).deliver_now
      true
    rescue => e
      Rails.logger.error("Inquiry delivery failed: #{e.class}: #{e.message}")
      @inquiry.errors.add(:base, :delivery_failed,
        message: "It did not send. Try again in a moment. If it fails twice, use the form on spencernorman.io and mention Norman Simplified.")
      false
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
