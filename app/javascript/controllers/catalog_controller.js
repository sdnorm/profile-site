import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["groups"]

  connect() {
    this.narrowScreen = window.matchMedia("(max-width: 47.999rem)")
    this.updateLayout = () => {
      this.groupsTargets.forEach((group) => {
        if (this.narrowScreen.matches && group.contains(document.activeElement)) {
          group.querySelector("summary").focus()
        }
        group.open = !this.narrowScreen.matches
      })
    }
    this.narrowScreen.addEventListener("change", this.updateLayout)
    this.updateLayout()
  }

  disconnect() {
    this.narrowScreen.removeEventListener("change", this.updateLayout)
  }
}
