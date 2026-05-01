class ChangeInvitationFromIdForeignKey < ActiveRecord::Migration[7.0]
  def change
    # Remove old foreign key to participants if it exists
    if foreign_key_exists?(:invitations, column: :from_id)
      remove_foreign_key :invitations, column: :from_id
    end

    # Ensure from_id is bigint to match teams.id
    change_column :invitations, :from_id, :bigint

    # Add new foreign key to teams
    unless foreign_key_exists?(:invitations, :teams, column: :from_id)
      add_foreign_key :invitations, :teams, column: :from_id
    end
  end
end