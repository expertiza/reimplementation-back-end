class AddNameToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :name, :string unless column_exists?(:teams, :name)
  end
end
