import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="session-timer"
export default class extends Controller {
  static targets = ["elapsedTime", "currentValue"]
  static values = {
    startTime: String,
    hourlyRate: Number,
    sessionId: Number,
    status: String
  }

  connect() {
    // Only update if session is active (aberta)
    if (this.statusValue === 'aberta') {
      this.updateDisplay()
      // Update every 60 seconds
      this.interval = setInterval(() => {
        this.updateDisplay()
      }, 60000)
    }
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  updateDisplay() {
    const startTime = new Date(this.startTimeValue)
    const now = new Date()
    const elapsedMs = now - startTime
    const elapsedMinutes = Math.floor(elapsedMs / 60000)
    const elapsedHours = elapsedMinutes / 60.0

    // Format elapsed time
    const hours = Math.floor(elapsedMinutes / 60)
    const minutes = elapsedMinutes % 60
    const formattedTime = `${hours}h ${minutes}min`

    // Calculate current value
    const currentValue = (elapsedHours * this.hourlyRateValue).toFixed(2)

    // Format with English number format (comma for thousands, dot for decimal)
    const formattedValue = parseFloat(currentValue).toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })

    // Update targets
    if (this.hasElapsedTimeTarget) {
      this.elapsedTimeTarget.textContent = formattedTime
    }

    if (this.hasCurrentValueTarget) {
      this.currentValueTarget.textContent = `${formattedValue} AOA`
    }
  }

  // Manual refresh button
  refresh(event) {
    event.preventDefault()
    this.updateDisplay()
  }
}
