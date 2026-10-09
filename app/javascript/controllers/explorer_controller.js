import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["steps", "buttons", "status"]

  connect() {
    this.index = 0
    this.buttonsTarget.hidden = false
    this.render()
  }

  disconnect() {
    this.stepsTargets.forEach((step) => { step.hidden = false })
    this.buttonsTarget.hidden = true
  }

  previous() {
    this.index = Math.max(0, this.index - 1)
    this.render()
  }

  next() {
    this.index = Math.min(this.stepsTargets.length - 1, this.index + 1)
    this.render()
  }

  render() {
    this.stepsTargets.forEach((step, index) => { step.hidden = index !== this.index })
    const buttons = this.buttonsTarget.querySelectorAll("button")
    buttons[0].disabled = this.index === 0
    buttons[1].disabled = this.index === this.stepsTargets.length - 1
    const title = this.stepsTargets[this.index].dataset.stepTitle
    this.statusTarget.textContent = `Step ${this.index + 1} of ${this.stepsTargets.length} — ${title}`
  }
}
