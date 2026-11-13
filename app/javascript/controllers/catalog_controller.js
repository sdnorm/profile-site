import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["groups"]

  connect() {
    this.groupsTargets.forEach((group) => { group.open = false })
  }

  trackOpen({ currentTarget, params }) {
    if (!currentTarget.closest("details").open) {
      window.posthog?.capture("catalog_group_opened", { group: params.group })
    }
  }
}
