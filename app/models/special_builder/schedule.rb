# frozen_string_literal: true

module SpecialBuilder
  # Which specials run on each date of a run of weeks, read in three queries: every week's lineup,
  # the days made different, and their specials. Only the collection's specials count (a special
  # trashed, or of another collection, drops out); `published_only` is what the site sees.
  class Schedule
    Lineup = Data.define(:date, :customised, :entries) do
      def weekday = date.cwday
    end

    attr_reader :from, :weeks

    # from: any date (the schedule starts on its week's Monday).
    def initialize(from: SpecialBuilder.today, weeks: 1, published_only: false)
      @from = from.beginning_of_week(:monday)
      @weeks = weeks.to_i.clamp(1, 53)
      @published_only = published_only
    end

    def dates = (from...(from + weeks * 7)).to_a

    def to = dates.last

    # {1 => [entry, …], … 7 => […]}: every week's lineup.
    def every_week
      @every_week ||= begin
        weekly = Placement.weekly.ordered.includes(:entry).to_a.group_by(&:weekday)
        (1..7).index_with { |weekday| specials(weekly.fetch(weekday, [])) }
      end
    end

    def lineups
      @lineups ||= begin
        days = Day.where(date: from..to).includes(placements: :entry).index_by(&:date)
        dates.map do |date|
          day = days[date]
          Lineup.new(date: date, customised: day.present?, entries: day ? specials(day.placements) : every_week[date.cwday])
        end
      end
    end

    def weeks_of_lineups = lineups.each_slice(7).to_a

    private

    def specials(placements)
      collection_id = collection&.id
      placements.filter_map(&:entry).select do |entry|
        entry.collection_id == collection_id && (!@published_only || entry.status == "published")
      end
    end

    def collection = defined?(@collection) ? @collection : (@collection = SpecialBuilder.collection)
  end
end
