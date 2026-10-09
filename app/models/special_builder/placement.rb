# frozen_string_literal: true

module SpecialBuilder
  # A special (a collection entry) in a slot: a weekday of every week, or a day made different.
  class Placement < ApplicationRecord
    belongs_to :entry, class_name: "::CollectionEntry", optional: true
    belongs_to :day, class_name: "SpecialBuilder::Day", optional: true, inverse_of: :placements

    validates :entry_id, presence: true
    validates :weekday, inclusion: {in: 1..7}, if: -> { day_id.nil? }
    validates :weekday, absence: true, if: :day_id?

    scope :weekly, -> { where(day_id: nil) }
    scope :ordered, -> { order(:position, :id) }

    class << self
      # The special in the slot, last in its lineup; a date takes its own lineup first (Day.customise).
      def place(entry, slot)
        transaction do
          placements = in_slot(slot)
          placements.find_or_create_by!(entry_id: entry.id) { it.position = (placements.maximum(:position) || -1) + 1 }
        end
      end

      # Out of the slot. From a date that ran every week's lineup, only that date loses it.
      def remove(entry, slot) = in_slot(slot).where(entry_id: entry.id).delete_all

      def move(entry, from:, to:)
        transaction do
          place(entry, to)
          remove(entry, from) unless from == to
        end
      end

      # On first switching on: each special's own `day` (as the site read it before the builder)
      # becomes its place in every week, unless the builder already has a weekly lineup.
      def import_weekly_lineup
        collection = SpecialBuilder.collection
        return if collection.nil? || weekly.exists?

        collection.entries.order(:title).each do |entry|
          frontmatter = entry.frontmatter.is_a?(Hash) ? entry.frontmatter : {}
          next if frontmatter.key?("active") && !ActiveModel::Type::Boolean.new.cast(frontmatter["active"])

          index = WEEKDAYS.index(frontmatter["day"].to_s.strip.capitalize) or next
          place(entry, Slot.every(index + 1))
        end
      end

      private

      def in_slot(slot)
        slot.weekly? ? weekly.where(weekday: slot.weekday) : Day.customise(slot.date).placements
      end
    end
  end
end
