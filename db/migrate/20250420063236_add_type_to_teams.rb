class AddTypeToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :type, :string
  end
end
