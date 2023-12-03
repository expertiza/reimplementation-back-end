# db/migrate/[timestamp]_create_teams_users.rb

class CreateTeamsUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :teams_users do |t|
      t.references :team, foreign_key: true
      t.references :user, foreign_key: true
      # Add other columns as needed
      t.timestamps
    end
  end
end
