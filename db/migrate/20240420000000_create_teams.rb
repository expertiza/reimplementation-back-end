class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.integer :max_team_size, null: false, default: 5

      t.timestamps
    end

    add_index :teams, :type
  end
end 
