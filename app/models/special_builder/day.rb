# frozen_string_literal: true

module SpecialBuilder
  # A date made different from every week: its specials are its own placements, and none at all
  # when it has none. A date without one runs the every-week lineup for its weekday.
  class Day < ApplicationRecord
    has_many :placements, -> { order(:position, :id) }, class_name: "SpecialBuilder::Placement", inverse_of: :day,
      dependent: :delete_all

    validates :date, presence: true, uniqueness: true

    # The date's own lineup, starting as every week's for its weekday, so a special dropped on it
    # joins that day's specials rather than replacing them.
    def self.customise(date)
      find_by(date: date) || transaction do
        create!(date: date).tap do |day|
          Placement.weekly.where(weekday: date.cwday).ordered.each do |weekly|
            day.placements.create!(entry_id: weekly.entry_id, position: weekly.position)
          end
        end
      end
    end

    # No special on this date.
    def self.clear(date) = customise(date).tap { it.placements.delete_all }

    # Back to the every-week lineup.
    def self.reset(date) = where(date: date).destroy_all
  end
end
