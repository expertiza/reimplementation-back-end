class RemoveParticipantRefFromInvitations < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:invitations, :participant_id)
      remove_reference :invitations, :participant
    end
  end
end
