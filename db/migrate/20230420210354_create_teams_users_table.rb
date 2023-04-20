class CreateTeamsUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table :teams_users_tables do |t|
      t.integer "team_id"
      t.integer "user_id"
      t.integer "duty_id"
      t.string "pair_programming_status", limit: 1
      t.index ["duty_id"], name: "index_teams_users_on_duty_id"
      t.index ["team_id"], name: "fk_users_teams"
      t.index ["user_id"], name: "fk_teams_users"
      t.timestamps
    end
  end
end
