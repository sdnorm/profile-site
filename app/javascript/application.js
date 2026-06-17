// Entry point for the importmap-managed JavaScript
import "@hotwired/turbo-rails"
import "./controllers"

document.addEventListener("turbo:submit-end", (event) => {
  if (event.target.id === "date-parse-form") {
    event.target.reset()
  }
})
