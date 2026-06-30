import { Controller } from "@hotwired/stimulus"

// Expandable work timeline. One entry open at a time (accordion).
export default class extends Controller {
  static targets = ["entry"]

  toggle(event) {
    const entry = event.currentTarget.closest(".sn-tl-entry")
    if (!entry) return
    const willOpen = !entry.classList.contains("is-open")
    this.entryTargets.forEach((el) => el.classList.remove("is-open"))
    if (willOpen) entry.classList.add("is-open")
  }
}
