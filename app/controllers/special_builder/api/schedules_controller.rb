# frozen_string_literal: true

module SpecialBuilder
  module Api
    # GET /api/special_builder/schedule — which specials run on each day, for the site's build:
    # every week's lineup and each date's, from ?from= (this week's Monday by default) for
    # ?weeks= weeks (Settings › Special Builder's number by default). A token that can't write
    # entries (the site's own) sees only published specials.
    class SchedulesController < ::Api::BaseController
      include PluginGated
      plugin :special_builder

      def show
        require_capability!("special_builder:read")

        from = begin
          Date.iso8601(params[:from].to_s)
        rescue Date::Error
          SpecialBuilder.today
        end
        @schedule = Schedule.new(from: from, weeks: params[:weeks].presence || SpecialBuilder.weeks_ahead,
          published_only: published_only?("entries"))
      end
    end
  end
end
