# frozen_string_literal: true

special = lambda do |json, entry|
  json.extract! entry, :id, :slug, :title, :status
  json.frontmatter entry.frontmatter.is_a?(Hash) ? entry.frontmatter : {}
end

json.data do
  json.collection SpecialBuilder.collection_slug
  json.time_zone Site.time_zone.tzinfo.name
  json.from @schedule.from.iso8601
  json.to @schedule.to.iso8601
  json.every_week do
    SpecialBuilder::WEEKDAYS.each_with_index do |name, index|
      json.set! name.downcase do
        json.array!(@schedule.every_week[index + 1]) { |entry| special.(json, entry) }
      end
    end
  end
  json.days @schedule.lineups do |lineup|
    json.date lineup.date.iso8601
    json.weekday SpecialBuilder::WEEKDAYS[lineup.weekday - 1]
    json.customised lineup.customised
    json.specials(lineup.entries) { |entry| special.(json, entry) }
  end
end
