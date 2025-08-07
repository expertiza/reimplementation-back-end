class AddNameToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :name, :string, null: false
    add_column :teams, :user_id, :bigint, null: false
    add_foreign_key :teams, :users
  end
end 
