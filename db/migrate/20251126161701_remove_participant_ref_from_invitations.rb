class RemoveParticipantRefFromInvitations < ActiveRecord::Migration[8.0]
  def change
    remove_reference :invitations, :participant
    remove_column :invitations, :participant_id, :integer
  end
end
