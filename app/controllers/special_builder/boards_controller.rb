# frozen_string_literal: true

module SpecialBuilder
  # The builder: the specials on one side, found by ?q= (ActiveSearch, as list screens search),
  # and the days of the next few weeks on the other, to drag them onto.
  class BoardsController < ApplicationController
    requires_capability "special_builder:read", only: :show

    before_action :set_collection

    def show
      @board = board_locals
      @can_write = @board[:can_write]
      @query = params[:q].to_s.strip
      @library = @collection ? @collection.entries.search_list(@query).order(:title).to_a : []
    end
  end
end
