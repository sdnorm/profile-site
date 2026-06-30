require "net/http"
require "json"

module Turnstile
  # Verifies a Cloudflare Turnstile token server-side (no Cloudflare Worker).
  # Tableless model. Fails closed (false) on a blank token or any error; bypasses
  # (true) when no secret is configured, so the form works in dev/test before real
  # keys exist. The HTTP boundary is injectable (plain DI) for tests — no mocks.
  class Verification
    include ActiveModel::Model
    include ActiveModel::Attributes

    ENDPOINT = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze

    attribute :token, :string
    attribute :remote_ip, :string
    attribute :secret, :string, default: -> { Rails.application.credentials.dig(:turnstile, :secret_key) }

    attr_writer :http
    def http = @http ||= method(:cloudflare_siteverify)

    def verified?
      return true if secret.blank?
      return false if token.blank?

      http.call(secret: secret, response: token, remoteip: remote_ip)["success"] == true
    rescue => e
      Rails.logger.warn("Turnstile verification error: #{e.class}: #{e.message}")
      false
    end

    private

    def cloudflare_siteverify(secret:, response:, remoteip: nil)
      params = { secret: secret, response: response }
      params[:remoteip] = remoteip if remoteip.present?
      http_response = Net::HTTP.post_form(URI(ENDPOINT), params)
      JSON.parse(http_response.body)
    end
  end
end
