class AddSubmissionFieldsToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :submitted_hyperlinks, :text
    add_column :teams, :directory_num, :integer
  end
end
