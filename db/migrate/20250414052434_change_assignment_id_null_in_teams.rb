class ChangeAssignmentIdNullInTeams < ActiveRecord::Migration[8.0]
  def change
    change_column_null :teams, :assignment_id, true
  end
end
