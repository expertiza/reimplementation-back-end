class CreateParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :participants do |t|
      t.references :user, foreign_key: true
      t.references :assignment, foreign_key: true
      t.index ["user_id"], name: "fk_participant_users"

      t.timestamps
    end
  end
end
