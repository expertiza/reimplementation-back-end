class CreateTeamsUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :teams_users do |t|
      t.column 'team_id', :bigint
      t.column 'user_id', :bigint
    end

    add_index 'teams_users', ['team_id'], name: 'fk_users_teams'

    execute "alter table teams_users
               add constraint fk_users_teams
               foreign key (team_id) references teams(id)"

    add_index 'teams_users', ['user_id'], name: 'fk_teams_users'

    execute "alter table teams_users
               add constraint fk_teams_users
               foreign key (user_id) references users(id)"
      t.timestamps

  end
end
