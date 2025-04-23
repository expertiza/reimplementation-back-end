class AddMentorIdToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :mentor_id, :bigint
    add_foreign_key :teams, :users, column: :mentor_id
    add_index :teams, :mentor_id
  end
end
