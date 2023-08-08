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
        ('Unregistered user', NULL, NULL, NOW(), NOW()),
        ('Student', NULL, 0, NOW(), NOW()),
        ('Teaching Assistant', 2, NULL, NOW(), NOW()),
        ('Instructor', 3, NULL, NOW(), NOW()),
        ('Administrator', 4, 8, NOW(), NOW()),
        ('Super Administrator', 5,  NULL, NOW(), NOW());
    SQL
  end
end
