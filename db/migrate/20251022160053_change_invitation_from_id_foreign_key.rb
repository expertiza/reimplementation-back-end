class ChangeInvitationFromIdForeignKey < ActiveRecord::Migration[8.0]
  def change
    if foreign_key_exists?(:invitations, column: :from_id)
      remove_foreign_key :invitations, column: :from_id
    end

    change_column :invitations, :from_id, :bigint unless column_for(:invitations, :from_id)&.type == :bigint

    unless foreign_key_exists?(:invitations, :participants, column: :from_id)
      add_foreign_key :invitations, :participants, column: :from_id
    end
  end

  private

  def column_for(table, column)
    connection.columns(table).find { |c| c.name == column.to_s }
  end
end
