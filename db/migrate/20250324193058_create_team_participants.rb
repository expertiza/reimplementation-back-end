# frozen_string_literal: true

class CreateTeamParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :team_participants do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :duty_id

      t.timestamps
    end
  end
end
