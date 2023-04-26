class CreateTeams < ActiveRecord::Migration[4.2]
  def self.up
    create_table 'teams', force: true do |t|
      t.column 'name', :string
      t.column 'assignment_id', :integer, default: 0, null: false
    end

    add_index 'teams', ['assignment_id'], name: 'fk_teams_assignments'
    
  end

  def self.down
    drop_table 'teams'
  end
end