class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.string :name
      t.bigint :parent_id
      t.integer :default_page_id

      t.timestamps
    end

    # Add foreign key to parent role
    add_foreign_key :roles, :roles, column: :parent_id, on_delete: :cascade

    # Insert initial data into the roles table
    execute <<~SQL
      INSERT INTO roles (name, parent_id, default_page_id, created_at, updated_at)
      VALUES
        ('Unregistered user', NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Student', NULL, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Teaching Assistant', 2, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Instructor', 3, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Administrator', 4, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Super Administrator', 5,  NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    SQL
  end
end
