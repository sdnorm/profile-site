# Server-side Cloudflare Turnstile check for public forms. Adds a base error to
# the record when verification fails so the form can re-render with it.
module TurnstileVerifiable
  extend ActiveSupport::Concern

  private

  def turnstile_verified_for?(record)
    verified = Turnstile::Verification.new(
      token: params["cf-turnstile-response"], remote_ip: request.remote_ip
    ).verified?
    record.errors.add(:base, "Please complete the verification and try again.") unless verified
    verified
  end
end
