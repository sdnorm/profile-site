import { Controller } from "@hotwired/stimulus"

// Explicitly renders the Cloudflare Turnstile widget. Turbo navigations don't
// fire window.onload, so we render on connect and wait for the async script.
export default class extends Controller {
  static values = { sitekey: String }

  connect() {
    if (!this.sitekeyValue) return
    this.renderWhenReady()
  }

  renderWhenReady() {
    if (window.turnstile) {
      this.widgetId = window.turnstile.render(this.element, {
        sitekey: this.sitekeyValue,
        action: "turnstile-spin-v1",
      })
    } else {
      this.readyTimer = setTimeout(() => this.renderWhenReady(), 100)
    }
  }

  disconnect() {
    if (this.readyTimer) clearTimeout(this.readyTimer)
    if (this.widgetId && window.turnstile) window.turnstile.remove(this.widgetId)
  }
}
