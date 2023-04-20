class CreateSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :signed_up_teams do |t|
      t.integer :topic_id, null: false, default: 0
      t.integer :team_id, null: false, default: 0
      t.boolean :is_waitlisted, null: false, default: false
      t.integer :preference_priority_number
      t.timestamps
    end
  end
end
