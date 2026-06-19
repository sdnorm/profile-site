import { Controller } from "@hotwired/stimulus"

// Contact form: validate, then swap to a success state.
// NOTE: does not deliver the message yet — wiring a mailer/backend is a follow-up.
export default class extends Controller {
  submit(event) {
    event.preventDefault()
    const form = event.target
    if (!form.checkValidity()) {
      form.reportValidity()
      return
    }
    this.element.classList.add("is-sent")
  }

  reset() {
    this.element.classList.remove("is-sent")
    const form = this.element.querySelector("form")
    if (form) form.reset()
  }
}
