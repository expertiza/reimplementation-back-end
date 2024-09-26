class CreateTeamsUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :teams_users do |t|
      t.string :pair_programming_status, limit: 1

      t.timestamps
    end

    add_reference :teams_users, :team, null: false, foreign_key: true
    add_reference :teams_users, :user, null: false, foreign_key: true
    add_reference :teams_users, :duty, foreign_key: true
    add_reference :teams_users, :participant, foreign_key: true

    add_index :teams_users, :pair_programming_status
    add_index :teams_users, :team_id, name: "fk_users_teams"
    add_index :teams_users, :user_id, name: "fk_teams_users"
    add_index :teams_users, :duty_id, name: "index_teams_participants_on_duty_id"
    add_index :teams_users, :participant_id, name: "fk_rails_f4d20198de"
  end
end