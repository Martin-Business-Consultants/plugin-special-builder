# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Special Builder plugin", type: :request do
  let(:admin) { create(:user) }
  let(:collection) { Collection.create!(name: "Specials", slug: "specials", schema: {"fields" => []}) }
  let!(:grille) { special("Chicago Grille", day: "Thursday", price: "$12") }
  let!(:tacos) { special("Fish Tacos", day: "Tuesday") }
  let!(:retired) { special("Old Burger", day: "Monday", active: false) }

  def special(title, day:, active: true, status: "published", price: nil)
    collection.entries.create!(title: title, slug: title.parameterize, status: status,
      frontmatter: {"day" => day, "active" => active, "price" => price}.compact)
  end

  def api_headers(user = admin) = {"Authorization" => "Bearer #{user.api_token.token}"}

  def schedule(user = admin, **params)
    get "/api/special_builder/schedule", params: params, headers: api_headers(user)
    JSON.parse(response.body)["data"]
  end

  def lineup(data, date) = data["days"].find { it["date"] == date.iso8601 }["specials"].map { it["title"] }

  let(:thursday) { SpecialBuilder.today.beginning_of_week(:monday) + 3 }

  context "while off" do
    it "is 404, pages and API alike" do
      sign_in_as admin

      get special_builder_board_path
      expect(response).to have_http_status(:not_found)

      get "/api/special_builder/schedule", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  context "while on" do
    before { switch_plugin :special_builder, on: true }

    it "takes each special's own day as every week's lineup, leaving out inactive ones" do
      expect(SpecialBuilder::Placement.weekly.pluck(:entry_id, :weekday)).to contain_exactly([grille.id, 4], [tacos.id, 2])

      data = schedule
      expect(data["every_week"]["thursday"].map { it["title"] }).to eq(["Chicago Grille"])
      expect(data["every_week"]["monday"]).to eq([])
      expect(lineup(data, thursday)).to eq(["Chicago Grille"])
      expect(data["days"].size).to eq(SpecialBuilder::DEFAULT_WEEKS_AHEAD * 7)
    end

    it "shows the builder with the specials to drag and the days to drop them on" do
      sign_in_as admin

      get special_builder_board_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chicago Grille", "Week by week", "special-builder--board", "special_builder_library", "$12")
      expect(response.body).not_to include(">Every week<")
    end

    it "finds specials as the search box is typed into, short terms too" do
      sign_in_as admin
      library = -> { Nokogiri::HTML(response.body).at_css("turbo-frame#special_builder_library").text.squish }

      get special_builder_board_path(q: "grill")
      expect(library.call).to include("Chicago Grille")
      expect(library.call).not_to include("Fish Tacos")

      get special_builder_board_path(q: "ta")
      expect(library.call).to include("Fish Tacos")
      expect(library.call).not_to include("Old Burger")

      get special_builder_board_path(q: "lobster")
      expect(library.call).to include("No special matches “lobster”")
    end

    it "adds a special to every week, and to one week's day only" do
      sign_in_as admin

      post special_builder_placements_path, params: {entry_id: tacos.id, weekday: 4}, as: :turbo_stream
      expect(response.body).to include("turbo-stream", "special_builder_board")
      expect(lineup(schedule, thursday)).to eq(["Chicago Grille", "Fish Tacos"])

      post special_builder_placements_path, params: {entry_id: retired.id, date: (thursday + 7).iso8601}
      expect(response).to redirect_to(special_builder_board_path(week: SpecialBuilder.today.beginning_of_week(:monday).iso8601))

      data = schedule
      expect(lineup(data, thursday + 7)).to eq(["Chicago Grille", "Fish Tacos", "Old Burger"])
      expect(data["days"].find { it["date"] == (thursday + 7).iso8601 }["customised"]).to be(true)
      expect(lineup(data, thursday + 14)).to eq(["Chicago Grille", "Fish Tacos"])
    end

    it "moves a special from day to day, and takes one off a single date" do
      sign_in_as admin

      post special_builder_placements_path, params: {entry_id: grille.id, weekday: 5, from: {weekday: 4}}, as: :turbo_stream
      data = schedule
      expect(data["every_week"]["thursday"]).to eq([])
      expect(data["every_week"]["friday"].map { it["title"] }).to eq(["Chicago Grille"])

      delete special_builder_placement_path(grille, date: (thursday + 1).iso8601), as: :turbo_stream
      data = schedule
      expect(lineup(data, thursday + 1)).to eq([])
      expect(lineup(data, thursday + 8)).to eq(["Chicago Grille"])
    end

    it "clears a date, then puts it back to every week's" do
      sign_in_as admin

      post special_builder_days_path, params: {date: thursday.iso8601}, as: :turbo_stream
      expect(lineup(schedule, thursday)).to eq([])

      delete special_builder_day_path(thursday.iso8601), as: :turbo_stream
      expect(lineup(schedule, thursday)).to eq(["Chicago Grille"])
    end

    it "rebuilds the site and keeps an audit row for each change" do
      sign_in_as admin
      announced = []
      subscriber = ActiveSupport::Notifications.subscribe("#{SpecialBuilder::EVENT}.cms") { |*, payload| announced << payload }

      post special_builder_placements_path, params: {entry_id: tacos.id, weekday: 1}

      expect(announced.size).to eq(1)
      expect(Webhook.deploy_events).to include(SpecialBuilder::EVENT)
      expect(AuditLog.where(action: "special_builder.placed").count).to eq(1)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it "gives a token that can't write entries only the published specials" do
      grille.update!(status: "draft")
      reader = create(:user, admin: false, role: create(:role, permissions: %w[special_builder:read]))

      expect(lineup(schedule(reader), thursday)).to eq([])
      expect(lineup(schedule, thursday)).to eq(["Chicago Grille"])
    end

    it "lets only those who may write the schedule change it" do
      reader = create(:user, admin: false, role: create(:role, permissions: %w[special_builder:read]))
      sign_in_as reader

      get special_builder_board_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("needs the Specials write permission")

      post special_builder_placements_path, params: {entry_id: tacos.id, weekday: 1}
      expect(response).not_to have_http_status(:success)
      expect(SpecialBuilder::Placement.weekly.where(weekday: 1)).to be_empty
    end

    it "answers a day it can't read and a special of another collection" do
      sign_in_as admin
      other = Collection.create!(name: "Posts", slug: "posts", schema: {"fields" => []})
      post_entry = other.entries.create!(title: "Hi", slug: "hi", status: "published")

      post special_builder_placements_path, params: {entry_id: tacos.id, date: "soon"}
      expect(flash[:alert]).to include("Say which day")

      post special_builder_placements_path, params: {entry_id: post_entry.id, weekday: 1}
      expect(response).to have_http_status(:not_found)
    end

    it "keeps its settings, and the API reads the collection they name" do
      sign_in_as admin

      patch special_builder_settings_path, params: {settings: {collection: "specials", weeks_ahead: 2}}

      expect(response).to redirect_to(special_builder_settings_path)
      expect(schedule["days"].size).to eq(14)
      expect(schedule(weeks: 1, from: (thursday + 7).iso8601)["from"]).to eq((thursday + 4).iso8601)
    end

    it "says so when there's no collection of specials" do
      Setting.set(SpecialBuilder::SETTING_KEY, {"collection" => "missing"})
      sign_in_as admin

      get special_builder_board_path

      expect(response.body).to include("no “missing” collection yet")
    end
  end
end
