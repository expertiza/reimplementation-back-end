class ChangeInvitationFromIdForeignKey < ActiveRecord::Migration[7.0]
  def change
    # Remove old foreign key to participants
    remove_foreign_key :invitations, column: :from_id

    # Add new foreign key to teams
    add_foreign_key :invitations, :teams, column: :from_id
  end
end