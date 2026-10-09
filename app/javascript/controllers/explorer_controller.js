import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["steps", "buttons", "status"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.buttonsTarget.hidden = false
    this.render()
  }

  disconnect() {
    this.stepsTargets.forEach((step) => { step.hidden = false })
    this.buttonsTarget.hidden = true
  }

  previous() {
    this.indexValue = Math.max(0, this.indexValue - 1)
    this.render()
    this.announce()
  }

  next() {
    this.indexValue = Math.min(this.stepsTargets.length - 1, this.indexValue + 1)
    this.render()
    this.announce()
  }

  render() {
    this.stepsTargets.forEach((step, index) => { step.hidden = index !== this.indexValue })
    const [previous, next] = this.buttonsTarget.querySelectorAll("button")
    const firstStep = this.indexValue === 0
    const lastStep = this.indexValue === this.stepsTargets.length - 1
    if (firstStep && document.activeElement === previous) next.focus()
    if (lastStep && document.activeElement === next) previous.focus()
    previous.disabled = firstStep
    next.disabled = lastStep
  }

  announce() {
    const title = this.stepsTargets[this.indexValue].dataset.stepTitle
    this.statusTarget.textContent = `Step ${this.indexValue + 1} of ${this.stepsTargets.length} — ${title}`
  }
}
