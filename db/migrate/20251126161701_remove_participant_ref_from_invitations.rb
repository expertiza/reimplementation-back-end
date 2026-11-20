class RemoveParticipantRefFromInvitations < ActiveRecord::Migration[8.0]
  def up
    # `remove_reference` drops the participant_id column together with its index
    # and foreign key in a single step. The original code then issued a redundant
    # `remove_column :invitations, :participant_id`, which aborted from-scratch
    # builds ("Can't DROP 'participant_id'; check that column/key exists") once
    # the column was already gone. Guarded so a re-run after an interrupted
    # migration is a no-op.
    if column_exists?(:invitations, :participant_id)
      remove_reference :invitations, :participant, index: true, foreign_key: true
    end
  end

  def down
    unless column_exists?(:invitations, :participant_id)
      add_reference :invitations, :participant, null: false, index: true, foreign_key: true
    end
  end
end

