import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "menu"]

  connect() {
    this.desktop = window.matchMedia("(min-width: 64rem)")
    this.onViewportChange = () => {
      const focusInMenu = this.menuTarget.contains(document.activeElement)
      this.close()
      if (!this.desktop.matches && focusInMenu) this.toggleTarget.focus()
    }
    this.desktop.addEventListener("change", this.onViewportChange)
    this.close()
    this.element.dataset.navReady = "true"
  }

  disconnect() {
    this.desktop.removeEventListener("change", this.onViewportChange)
    delete this.element.dataset.navReady
    this.close()
  }

  toggle() {
    const expanded = this.toggleTarget.getAttribute("aria-expanded") === "true"
    this.toggleTarget.setAttribute("aria-expanded", String(!expanded))
  }

  escape(event) {
    if (this.toggleTarget.getAttribute("aria-expanded") !== "true") return

    event.preventDefault()
    this.close()
    this.toggleTarget.focus()
  }

  followLink(event) {
    if (event.target.closest("a")) this.close()
  }

  close() {
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }
}
