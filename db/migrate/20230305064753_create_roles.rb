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
      INSERT INTO roles (name, parent_id, created_at, updated_at)
      VALUES
        ('Super Administrator', NULL, NOW(), NOW()),
        ('Administrator', 1, NOW(), NOW()),
        ('Instructor', 2, NOW(), NOW()),
        ('Teaching Assistant', 3,  NOW(), NOW()),
        ('Student', 4, NOW(), NOW());
    SQL
  end
end
