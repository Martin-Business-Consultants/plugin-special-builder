# frozen_string_literal: true

module SpecialBuilder
  # The builder: the specials on one side, and the days of every week and of the next few weeks
  # on the other, to drag them onto.
  class BoardsController < ApplicationController
    requires_capability "special_builder:read", only: :show

    before_action :set_collection

    def show
      @board = board_locals
    end
  end
end
