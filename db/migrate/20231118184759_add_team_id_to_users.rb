class AddTeamIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :team_id, :bigint
    add_foreign_key :users, :teams, column: :team_id
  end
end
