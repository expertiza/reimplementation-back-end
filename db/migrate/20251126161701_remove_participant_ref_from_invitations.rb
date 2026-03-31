class RemoveParticipantRefFromInvitations < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:invitations, :participant_id)
      if foreign_key_exists?(:invitations, :participants, column: :participant_id)
        remove_foreign_key :invitations, column: :participant_id
      end

      if index_exists?(:invitations, :participant_id)
        remove_index :invitations, :participant_id
      end

      remove_column :invitations, :participant_id
    end
  end
end
