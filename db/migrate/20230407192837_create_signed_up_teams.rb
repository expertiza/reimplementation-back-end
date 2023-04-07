class CreateSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :signed_up_teams do |t|
      t.integer :preference_priority_number

      t.timestamps
    end
  end
end
