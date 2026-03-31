class ChangeInvitationFromIdForeignKey < ActiveRecord::Migration[7.0]
  def change
    change_column :invitations, :from_id, :bigint

    # Remove old foreign key to participants
    if foreign_key_exists?(:invitations, column: :from_id)
      remove_foreign_key :invitations, column: :from_id
    end
    # Add new foreign key to teams
    unless foreign_key_exists?(:invitations, column: :from_id)
      add_foreign_key :invitations, :teams, column: :from_id
    end 
  end
end