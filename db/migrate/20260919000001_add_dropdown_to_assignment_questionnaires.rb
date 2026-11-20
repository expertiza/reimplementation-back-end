class AddDropdownToAssignmentQuestionnaires < ActiveRecord::Migration[7.0]
  # The 20260320011304 legacy bridge migration adds :dropdown on a migrated
  # database, and it also runs on a from-scratch chain, so the column may
  # already exist by the time this migration runs. Guard to keep the merged
  # chain idempotent on both database paths.
  def up
    add_column :assignment_questionnaires, :dropdown, :boolean, default: false, null: false unless column_exists?(:assignment_questionnaires, :dropdown)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
