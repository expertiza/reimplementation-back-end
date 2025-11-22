class AddNameToTeams < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:teams, :name)
      add_column :teams, :name, :string
    end
  end
end
