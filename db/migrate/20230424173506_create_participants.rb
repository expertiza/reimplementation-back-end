class CreateParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :participants do |t|
      t.integer "user_id"
      t.integer "parent_id"
      t.index ["user_id"], name: "fk_participant_users"

      t.timestamps
    end
  end
end
