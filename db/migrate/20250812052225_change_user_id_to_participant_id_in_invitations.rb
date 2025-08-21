class ChangeUserIdToParticipantIdInInvitations < ActiveRecord::Migration[8.0]
  def change
    # Remove old columns
    remove_column :invitations, :from_id, :integer
    remove_column :invitations, :to_id, :integer

    # Add new participant references with explicit names
    add_reference :invitations, :from, null: false, foreign_key: { to_table: :participants }
    add_reference :invitations, :to, null: false, foreign_key: { to_table: :participants }
  end
end