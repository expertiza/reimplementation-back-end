class AddParticipantRefToInvitations < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:invitations, :participant_id)
      add_reference :invitations, :participant, null: false, foreign_key: true
    end
  end
end