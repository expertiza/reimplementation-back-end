class AddDirectoryNumToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :directory_num, :integer
  end
end
