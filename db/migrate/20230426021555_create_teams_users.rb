class CreateTeamsUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table 'teams_users', force: true do |t|
      t.column 'team_id', :integer
      t.column 'user_id', :integer
    end

    add_index 'teams_users', ['team_id'], name: 'fk_users_teams'
    
  end

  def self.down
    drop_table 'teams_users'
  end
end