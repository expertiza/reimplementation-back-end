class CreateTeamsUsers < ActiveRecord::Migration[7.0]
  def self.up
    drop_table 'teams_users'
    create_table 'teams_users' do |t|
      t.column 'team_id', :integer
      t.column 'user_id', :integer
      t.timestamps
    end
    add_index 'teams_users', ['team_id'], name: 'fk_users_teams'

    # execute <<-SQL
    #   ALTER TABLE teams_users
    #   ADD CONSTRAINT fk_users_teams
    #   FOREIGN KEY (team_id) REFERENCES teams(id)
    # SQL

    add_index 'teams_users', ['user_id'], name: 'fk_teams_users'

    # execute <<-SQL
    #   ALTER TABLE teams_users
    #   ADD CONSTRAINT fk_teams_users
    #   FOREIGN KEY (user_id) REFERENCES users(id)
    # SQL
  end

  def self.down
    drop_table 'teams_users'
  end
end
