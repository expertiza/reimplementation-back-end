class AddDropdownToAssignmentQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    add_column :assignment_questionnaires, :dropdown, :boolean, default: false, null: false
  end
end
