class AddSubmissionFieldsToTeams < ActiveRecord::Migration[8.0]
  # CreateTeams (20231102173152) already declares submitted_hyperlinks and
  # directory_num, so on a database built from the 2023-2026 chain these
  # add_columns are duplicates and abort a from-scratch build with "Duplicate
  # column name". Guard each so only whichever is actually missing gets added.
  def change
    add_column :teams, :submitted_hyperlinks, :text unless column_exists?(:teams, :submitted_hyperlinks)
    add_column :teams, :directory_num, :integer unless column_exists?(:teams, :directory_num)
  end
end

