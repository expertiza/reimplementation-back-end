class ChangeTeamsUsersTablesToTeamsUsers < ActiveRecord::Migration[7.0]
  def change
    rename_table :teams_users_tables, :teams_users
  end
end
