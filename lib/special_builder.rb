# frozen_string_literal: true

require "special_builder/version"
require "special_builder/engine"

# Special Builder: which specials run on which day. The specials themselves are a collection's
# entries (`specials` unless Settings › Special Builder names another); this plugin holds the
# schedule — a lineup for every week, and the days someone has made different — and the site
# reads it from /api/special_builder/schedule.
module SpecialBuilder
  SETTING_KEY = "special_builder"
  DEFAULT_COLLECTION = "specials"
  DEFAULT_WEEKS_AHEAD = 8

  # Day names by Date#cwday - 1: Monday first.
  WEEKDAYS = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].freeze

  # The event a change to the schedule announces: a webhook may hear it, and it rebuilds the site.
  EVENT = "specials.scheduled"

  # Plugin tables are prefixed with the plugin's key.
  def self.table_name_prefix = "special_builder_"

  def self.settings = Setting.get(SETTING_KEY)

  def self.collection_slug = settings["collection"].presence || DEFAULT_COLLECTION

  # The collection the specials are entries of, or nil until it exists.
  def self.collection = Collection.find_by(slug: collection_slug)

  # How many weeks the site is given, from this one: it picks today's from them, so it needs
  # rebuilding only when the schedule changes, and once a week to look further ahead.
  def self.weeks_ahead = (settings["weeks_ahead"].presence || DEFAULT_WEEKS_AHEAD).to_i.clamp(1, 53)

  def self.today = Time.use_zone(Site.time_zone) { Date.current }

  # Something changed what the site shows: rebuild it, and tell any webhook.
  def self.announce_change(reason)
    Event.announce(EVENT, {reason: reason, at: Time.current.iso8601})
  end
end
