# frozen_string_literal: true

module SpecialBuilder
  # A CMS plugin (docs/plugins.md): it owns its tables (special_builder_*), reaches the specials
  # (a collection's entries) by id, and extends the core only through Cms::Plugins. Remove it and
  # the CMS runs as before.
  class Engine < ::Rails::Engine
    initializer "special_builder.migrations" do |app|
      config.paths["db/migrate"].expanded.each { |path| app.config.paths["db/migrate"] << path }
    end

    initializer "special_builder.routes" do |app|
      app.routes.append do
        scope "special_builder", module: "special_builder", as: "special_builder" do
          resource :board, only: :show
          # :id is the special (its entry); the slot it's in comes as weekday or date.
          resources :placements, only: [:create, :destroy]
          resources :days, only: [:create, :destroy], param: :date
          resource :settings, only: [:show, :update]
        end

        scope "api/special_builder", module: "special_builder/api", as: "api_special_builder", defaults: {format: :json} do
          resource :schedule, only: :show
        end
      end
    end

    # The board's Stimulus controller (special-builder--board), pinned beside the admin's.
    initializer "special_builder.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    initializer "special_builder.assets" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    config.to_prepare do
      Cms::Plugins.register :special_builder, name: "Special Builder", version: SpecialBuilder::VERSION,
        author: "Martin Business Consultants", enabled_by_default: false, requires: ">= 1.2",
        homepage: "https://github.com/Martin-Business-Consultants/plugin-special-builder",
        description: "A builder for daily specials: drag specials onto the days of every week, or onto one " \
                     "week's day to make it different. The site reads the schedule and shows today's."

      Cms::Plugins.menu :special_builder, :special_builder, label: "Specials", icon: "calendar", group: "Content",
        after: :collections, path: -> { special_builder_board_path }, capability: "special_builder:read"
      Cms::Plugins.submenu :special_builder, :special_builder, label: "Builder", path: -> { special_builder_board_path },
        capability: "special_builder:read"
      Cms::Plugins.submenu :special_builder, :special_builder, label: "Settings", path: -> { special_builder_settings_path },
        capability: "settings:read", after: "Builder"
      Cms::Plugins.settings :special_builder, "Special Builder", -> { special_builder_settings_path },
        description: "Which collection holds the specials, and how many weeks the site is given.", capability: "settings:read"
      Cms::Plugins.permissions :special_builder, "Specials", %w[special_builder:read special_builder:write],
        after: "Globals",
        defaults: {editor: %w[special_builder:read special_builder:write], author: %w[special_builder:read],
                   site: %w[special_builder:read], agent: %w[special_builder:read]}
      Cms::Plugins.stylesheet :special_builder, "special_builder/special_builder"
      # A change to the schedule changes the public site, so it rebuilds it.
      Cms::Plugins.webhook_events :special_builder, "Specials", [SpecialBuilder::EVENT], deploy: true
      # The site is given weeks_ahead weeks from the one it's built in; each Monday it looks a week further.
      Cms::Plugins.nightly :special_builder, -> { SpecialBuilder.announce_change("new week") if SpecialBuilder.today.monday? }
      # On first switching on: the specials' own `day` becomes the every-week lineup.
      Cms::Plugins.bootstrap :special_builder, -> { SpecialBuilder::Placement.import_weekly_lineup }
      Cms::Plugins.api :special_builder, "/api/special_builder/schedule",
        description: "Which specials run on each day, from ?from= (a date; this week's Monday by default) for ?weeks= weeks."
    end
  end
end
