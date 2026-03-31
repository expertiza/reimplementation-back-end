class RemoveParticipantRefFromInvitations < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:invitations, :participant_id)
      remove_reference :invitations, :participant
      if column_exists?(:invitations, :participant_id)
        remove_column :invitations, :participant_id, :integer
      end
    end
  end
end
