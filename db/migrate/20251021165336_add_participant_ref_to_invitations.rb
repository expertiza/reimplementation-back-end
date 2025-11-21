class AddParticipantRefToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_reference :invitations, :participant, null: false, foreign_key: true
  end
end