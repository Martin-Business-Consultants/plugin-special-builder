import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

// The Special Builder: drag a special from the list onto a day (a copy), or from one day to
// another (a move). A drop posts to placements, which answers with the board again (a morph).
export default class extends Controller {
  static targets = [ "cell" ]
  static values = { url: String }

  dragStart(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = this.dragged.dataset.from ? "move" : "copy"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.entryId)
    this.dragged.classList.add("special-builder-chip--dragging")
  }

  dragOver(event) {
    if (!this.dragged) return
    event.preventDefault()
    event.dataTransfer.dropEffect = this.dragged.dataset.from ? "move" : "copy"
    event.currentTarget.classList.add("special-builder-cell--over")
  }

  dragLeave(event) {
    if (event.currentTarget.contains(event.relatedTarget)) return
    event.currentTarget.classList.remove("special-builder-cell--over")
  }

  async drop(event) {
    event.preventDefault()
    const cell = event.currentTarget
    const chip = this.dragged
    this.#clear()
    if (!chip) return

    const body = new FormData()
    body.append("entry_id", chip.dataset.entryId)
    this.#append(body, JSON.parse(cell.dataset.slot))
    if (chip.dataset.from) {
      const from = JSON.parse(chip.dataset.from)
      if (JSON.stringify(from) === cell.dataset.slot) return
      this.#append(body, from, "from")
    }

    await post(this.urlValue, { body, responseKind: "turbo-stream" })
  }

  dragEnd() {
    this.#clear()
  }

  #append(body, slot, scope) {
    Object.entries(slot).forEach(([ name, value ]) => body.append(scope ? `${scope}[${name}]` : name, value))
  }

  #clear() {
    this.dragged?.classList.remove("special-builder-chip--dragging")
    this.dragged = null
    this.cellTargets.forEach(cell => cell.classList.remove("special-builder-cell--over"))
  }
}
