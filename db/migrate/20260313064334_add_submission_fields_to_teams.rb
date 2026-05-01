class AddSubmissionFieldsToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :submitted_hyperlinks, :text unless column_exists?(:teams, :submitted_hyperlinks)
    add_column :teams, :directory_num, :integer unless column_exists?(:teams, :directory_num)
  end
end
