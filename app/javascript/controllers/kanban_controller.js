import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="kanban"
export default class extends Controller {
  static targets = ["card", "column"]

  connect() {
    console.log("Kanban controller connected")
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    // Set up drop zones
    this.columnTargets.forEach(column => {
      column.addEventListener('dragover', this.dragOver.bind(this))
      column.addEventListener('drop', this.drop.bind(this))
      column.addEventListener('dragleave', this.dragLeave.bind(this))
    })
  }

  dragStart(event) {
    const card = event.target
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/html', card.innerHTML)
    event.dataTransfer.setData('opportunity-id', card.dataset.opportunityId)

    card.classList.add('dragging')

    // Store the card element for later use
    this.draggedCard = card
  }

  dragEnd(event) {
    event.target.classList.remove('dragging')

    // Remove drag-over class from all columns
    this.columnTargets.forEach(column => {
      column.classList.remove('drag-over')
    })
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'

    const column = event.currentTarget
    column.classList.add('drag-over')
  }

  dragLeave(event) {
    const column = event.currentTarget

    // Only remove class if we're actually leaving the column
    if (!column.contains(event.relatedTarget)) {
      column.classList.remove('drag-over')
    }
  }

  drop(event) {
    event.preventDefault()

    const column = event.currentTarget
    column.classList.remove('drag-over')

    const opportunityId = event.dataTransfer.getData('opportunity-id')
    const newStage = column.dataset.stage

    if (!opportunityId || !newStage) {
      console.error('Missing opportunity ID or stage')
      return
    }

    // Update the opportunity stage via AJAX
    this.updateOpportunityStage(opportunityId, newStage, column)
  }

  updateOpportunityStage(opportunityId, newStage, targetColumn) {
    const url = `/opportunities/${opportunityId}/update_stage`
    const token = document.querySelector('meta[name="csrf-token"]').content

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ stage: newStage })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Move the card to the new column
        if (this.draggedCard) {
          targetColumn.appendChild(this.draggedCard)
          this.draggedCard.classList.remove('dragging')
          this.draggedCard = null
        }

        // Reload the page to update counts and totals
        window.location.reload()
      } else {
        alert('Erro ao atualizar oportunidade: ' + (data.error || 'Erro desconhecido'))
        console.error('Error updating opportunity:', data.error)
      }
    })
    .catch(error => {
      alert('Erro ao atualizar oportunidade')
      console.error('Error:', error)
    })
  }
}
