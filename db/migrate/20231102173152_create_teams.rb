# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string  :name, null: false
      t.string  :type, null: false # STI class name
      t.integer :parent_id, null: false # points to assignment, course, etc.

      t.timestamps
    end

    add_index :teams, :type
  end
end
