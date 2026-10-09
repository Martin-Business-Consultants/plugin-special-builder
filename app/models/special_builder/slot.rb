# frozen_string_literal: true

module SpecialBuilder
  # Where a special goes: a weekday of every week (1 Monday … 7 Sunday, as Date#cwday) or one date.
  Slot = Data.define(:weekday, :date) do
    # From a request's weekday= or date=; nil when it names neither.
    def self.from(params)
      if params[:date].present?
        new(weekday: nil, date: Date.iso8601(params[:date].to_s))
      elsif params[:weekday].to_s.match?(/\A[1-7]\z/)
        new(weekday: params[:weekday].to_i, date: nil)
      end
    rescue Date::Error
      nil
    end

    def self.every(weekday) = new(weekday: weekday, date: nil)
    def self.on(date) = new(weekday: nil, date: date)

    def weekly? = date.nil?

    def label = weekly? ? "every #{SpecialBuilder::WEEKDAYS[weekday - 1]}" : date.strftime("%A, %B %-d, %Y")

    def to_param = weekly? ? {weekday: weekday} : {date: date.iso8601}
  end
end
