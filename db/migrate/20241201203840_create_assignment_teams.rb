class CreateAssignmentTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :assignment_teams do |t|

      t.timestamps
    end
  end
end
