class CreateSignUpTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :sign_up_teams do |t|
      t.references :sign_up_topic, null: false, foreign_key: true
      t.boolean :is_waitlisted

      t.timestamps
    end
  end
end
