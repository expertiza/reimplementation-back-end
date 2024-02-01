class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.integer "assignment_id"
      t.integer "from_id"
      t.integer "to_id"
      t.string "reply_status", limit: 1
      t.index ["assignment_id"], name: "fk_invitation_assignments"
      t.index ["from_id"], name: "fk_invitationfrom_users"
      t.index ["to_id"], name: "fk_invitationto_users"

      t.timestamps
    end
  end
end
