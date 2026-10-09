# frozen_string_literal: true

# Special Builder's tables, prefixed with its key. The specials are collection entries, pointed at
# by id. A placement is a special on a weekday of every week (weekday, no day) or on one date that
# was made different (a day); a day with no placements has no special.
class CreateSpecialBuilder < ActiveRecord::Migration[8.1]
  def change
    create_table :special_builder_days do |t|
      t.date :date, null: false, index: {unique: true}
      t.timestamps
    end

    create_table :special_builder_placements do |t|
      t.integer :entry_id, null: false, index: true
      t.integer :weekday
      t.references :day, foreign_key: {to_table: :special_builder_days, on_delete: :cascade}
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index [:weekday, :entry_id], unique: true, where: "day_id IS NULL"
      t.index [:day_id, :entry_id], unique: true, where: "day_id IS NOT NULL"
    end
  end
end
