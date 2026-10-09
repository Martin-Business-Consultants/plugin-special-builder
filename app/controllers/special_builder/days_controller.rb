# frozen_string_literal: true

module SpecialBuilder
  # One date made to have no special (create), or put back to every week's lineup (destroy).
  class DaysController < ApplicationController
    requires_capability "special_builder:write", only: [:create, :destroy]

    before_action :set_collection, :set_date

    def create
      Day.clear(@date)
      message = "No special on #{Slot.on(@date).label}"
      record_change("cleared", message)
      respond_with_board(:notice, message)
    end

    def destroy
      Day.reset(@date)
      message = "#{Slot.on(@date).label} runs every week's specials again"
      record_change("reset", message)
      respond_with_board(:notice, message)
    end

    private

    def set_date
      @date = Date.iso8601(params[:date].to_s)
    rescue Date::Error
      respond_with_board(:alert, "That isn't a date (YYYY-MM-DD).")
    end
  end
end
