# frozen_string_literal: true

module SpecialBuilder
  # The builder's pages: 404 while the plugin is off. Every change answers the board's drag and
  # drop with the board again (a morph, so the page keeps its place), or a plain post with a
  # redirect to it, at the week being looked at.
  class ApplicationController < ::ApplicationController
    include PluginGated
    plugin :special_builder

    WEEKS_SHOWN = 4

    helper_method :week

    private

    # The first week shown: ?week= (any date in it), else this one.
    def week
      @week ||= begin
        Date.iso8601(params[:week].to_s)
      rescue Date::Error
        SpecialBuilder.today
      end.beginning_of_week(:monday)
    end

    def set_collection
      @collection = SpecialBuilder.collection
    end

    def board_locals
      {schedule: Schedule.new(from: week, weeks: WEEKS_SHOWN), collection: @collection,
       library: @collection ? @collection.entries.order(:title).to_a : [],
       can_write: Current.user.can?("special_builder:write")}
    end

    def respond_with_board(kind, message)
      respond_to do |format|
        format.turbo_stream do
          flash.now[kind] = message
          render turbo_stream: [
            turbo_stream.replace("special_builder_board", partial: "special_builder/boards/board", method: :morph, locals: board_locals),
            turbo_stream.replace("flash", partial: "layouts/shared/flash")
          ]
        end
        format.html { redirect_to special_builder_board_path(week: week.iso8601), kind => message }
      end
    end

    # Something the site shows changed: the audit log has it, and the site rebuilds.
    def record_change(action, message, entry: nil)
      Event.record("special_builder.#{action}", target: entry, change: message)
      SpecialBuilder.announce_change(message)
    end
  end
end
