class AddSubmissionFieldsToTeams < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:teams, :submitted_hyperlinks)
      add_column :teams, :submitted_hyperlinks, :text
    end
    unless column_exists?(:teams, :directory_num)
      add_column :teams, :directory_num, :integer
    end
  end
end
