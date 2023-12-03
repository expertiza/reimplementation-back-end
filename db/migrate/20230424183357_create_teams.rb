class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :name  # Add this line to include the 'name' column
      # Add other columns as needed
      t.timestamps
    end
  end
end
