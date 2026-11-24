class RenameNameColumnsInUsers < ActiveRecord::Migration[8.0]
  # The 20260320011304 legacy bridge migration performs the same renames on
  # a migrated database (legacy `name`/`fullname` -> `username`/`name`), so
  # each rename is guarded to keep the merged chain idempotent on both paths.
  def up
    rename_column :users, :name, :username if column_exists?(:users, :name) && !column_exists?(:users, :username)
    rename_column :users, :full_name, :name if column_exists?(:users, :full_name) && !column_exists?(:users, :name)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
