# frozen_string_literal: true

class CreateSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :signed_up_teams do |t|
      t.references :sign_up_topic, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.boolean :is_waitlisted
      t.integer :preference_priority_number

      t.timestamps
    end
  end
end
