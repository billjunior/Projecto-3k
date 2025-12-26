import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["discountInput", "justification", "warningContainer", "warningContent"]

  connect() {
    this.debounceTimer = null
    console.log("Pricing validator controller connected")
  }

  validateDiscount() {
    this.validateJustification()
    this.performServerValidation()
  }

  validateJustification() {
    const discount = parseFloat(this.discountInputTarget.value) || 0
    const justification = this.justificationTarget.value.trim()

    // Validate justification requirement
    if (discount > 0 && justification.length < 10) {
      this.justificationTarget.classList.add('is-invalid')
      this.justificationTarget.classList.remove('is-valid')
    } else if (discount > 0 && justification.length >= 10) {
      this.justificationTarget.classList.remove('is-invalid')
      this.justificationTarget.classList.add('is-valid')
    } else {
      // No discount, clear validation
      this.justificationTarget.classList.remove('is-invalid', 'is-valid')
    }
  }

  performServerValidation() {
    // Debounce server calls
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.callValidationEndpoint()
    }, 800)
  }

  async callValidationEndpoint() {
    try {
      const formData = this.collectFormData()

      // Determine if we're on estimates or invoices
      const isEstimate = window.location.pathname.includes('/estimates')
      const endpoint = isEstimate ? '/estimates/validate_pricing' : '/invoices/validate_pricing'

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify(formData)
      })

      if (!response.ok) {
        console.error('Validation request failed:', response.status)
        return
      }

      const data = await response.json()
      console.log('Pricing analysis:', data)

      if (data.analysis && data.analysis.below_margin_items && data.analysis.below_margin_items.length > 0) {
        this.displayWarnings(data.analysis)
      } else {
        this.hideWarnings()
      }
    } catch (error) {
      console.error('Error validating pricing:', error)
    }
  }

  displayWarnings(analysis) {
    let html = '<ul class="mb-0">'

    // Overall margin warning
    if (analysis.margin_deficit && analysis.margin_deficit > 0) {
      html += `<li><strong>Margem Abaixo do Esperado:</strong> Esperado ${analysis.expected_margin}%, Real ${analysis.actual_margin_percentage}%</li>`
    }

    // Item-level warnings
    analysis.below_margin_items.forEach(item => {
      html += `<li><strong>${item.product_name}:</strong> Margem ${item.margin_percentage}% (abaixo de ${analysis.expected_margin}%)</li>`
    })

    html += '</ul>'

    if (this.hasWarningContentTarget) {
      this.warningContentTarget.innerHTML = html
      this.warningContainerTarget.style.display = 'block'
    }
  }

  hideWarnings() {
    if (this.hasWarningContainerTarget) {
      this.warningContainerTarget.style.display = 'none'
    }
  }

  collectFormData() {
    // Get all form data needed for validation
    const estimate = {
      discount_percentage: parseFloat(this.discountInputTarget.value) || 0,
      discount_justification: this.justificationTarget.value,
      estimate_items_attributes: this.collectItems()
    }

    // Add customer_id if available
    const customerSelect = document.querySelector('select[name*="[customer_id]"]')
    if (customerSelect) {
      estimate.customer_id = customerSelect.value
    }

    return { estimate }
  }

  collectItems() {
    const items = []
    const itemElements = document.querySelectorAll('.estimate-item, .invoice-item')

    itemElements.forEach((itemEl, index) => {
      const destroyField = itemEl.querySelector('.item-destroy')
      if (destroyField && destroyField.value === 'true') return

      const productSelect = itemEl.querySelector('.product-select')
      const quantityInput = itemEl.querySelector('.quantity-input')
      const priceInput = itemEl.querySelector('.price-input')

      if (productSelect && quantityInput && priceInput) {
        items.push({
          product_id: productSelect.value,
          quantity: parseFloat(quantityInput.value) || 0,
          unit_price: parseFloat(priceInput.value) || 0
        })
      }
    })

    return items
  }
}
