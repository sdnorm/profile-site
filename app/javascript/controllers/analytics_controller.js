import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { onConnect: String, properties: Object, captured: Boolean }

  connect() {
    if (this.hasOnConnectValue && !this.capturedValue) {
      this.capturedValue = this.capture(this.onConnectValue, this.propertiesValue)
    }
  }

  track({ params }) {
    const { event, ...properties } = params
    this.capture(event, properties)
  }

  capture(event, properties) {
    if (!event || typeof window.posthog?.capture !== "function") return false

    window.posthog.capture(event, properties)
    return true
  }
}
