# frozen_string_literal: true

module SpecialBuilder
  # A special dropped on a day (weekday= of every week, or date=), from the list or from another
  # day (from[weekday]= / from[date]=: a move), and taken off one. :id is the special.
  class PlacementsController < ApplicationController
    requires_capability "special_builder:write", only: [:create, :destroy]

    before_action :set_collection, :set_entry, :set_slot

    def create
      from = Slot.from(params.fetch(:from, {}))
      if from
        Placement.move(@entry, from: from, to: @slot)
        message = "Moved #{@entry.title} from #{from.label} to #{@slot.label}"
      else
        Placement.place(@entry, @slot)
        message = "#{@entry.title} runs #{@slot.label}"
      end

      record_change(from ? "moved" : "placed", message, entry: @entry)
      respond_with_board(:notice, message)
    end

    def destroy
      Placement.remove(@entry, @slot)
      message = "#{@entry.title} no longer runs #{@slot.label}"
      record_change("removed", message, entry: @entry)
      respond_with_board(:notice, message)
    end

    private

    def set_entry
      return respond_with_board(:alert, "There's no specials collection yet.") unless @collection

      @entry = @collection.entries.find(params[:entry_id] || params[:id])
    end

    def set_slot
      @slot = Slot.from(params) or respond_with_board(:alert, "Say which day: weekday (1–7) or date (YYYY-MM-DD).")
    end
  end
end
