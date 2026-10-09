# frozen_string_literal: true

module SpecialBuilder
  # Which collection holds the specials, and how many weeks the site is given.
  class SettingsController < ::Settings::BaseController
    include PluginGated
    plugin :special_builder

    requires_capability "settings:read", only: :show
    requires_capability "settings:write", only: :update

    def show
      @settings = SpecialBuilder.settings
      @collections = Collection.order(:name).pluck(:name, :slug)
    end

    def update
      attributes = params.require(:settings).permit(:collection, :weeks_ahead)
      Setting.set(SETTING_KEY, {"collection" => attributes[:collection].to_s.strip.presence || DEFAULT_COLLECTION,
                                "weeks_ahead" => attributes[:weeks_ahead].to_i.clamp(1, 53)})
      Event.record("settings.special_builder_updated")
      SpecialBuilder.announce_change("settings")
      redirect_to special_builder_settings_path, notice: "Special Builder settings saved"
    end
  end
end
