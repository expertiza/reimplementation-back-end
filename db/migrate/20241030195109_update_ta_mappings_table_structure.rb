class UpdateTaMappingsTableStructure < ActiveRecord::Migration[7.0]
  def change
    # Remove foreign key constraint on user_id if it exists
    if foreign_key_exists?(:ta_mappings, column: :user_id)
      remove_foreign_key :ta_mappings, column: :user_id
    end

    change_table :ta_mappings do |t|
      # Remove user_id column and related indexes if they exist
      t.remove_index name: "fk_ta_mapping_users" if index_exists?(:ta_mappings, :user_id, name: "fk_ta_mapping_users")
      t.remove_index name: "index_ta_mappings_on_user_id" if index_exists?(:ta_mappings, :user_id, name: "index_ta_mappings_on_user_id")
      t.remove :user_id if column_exists?(:ta_mappings, :user_id)

      # Ensure ta_id column exists and add it if it doesn't
      t.bigint :ta_id, null: false unless column_exists?(:ta_mappings, :ta_id)
    end
    
    # Add the foreign key constraint to ta_id
    add_foreign_key :ta_mappings, :users, column: :ta_id

    # Add necessary indexes outside of the change_table block to avoid conflicts
    add_index :ta_mappings, :course_id, name: "index_ta_mappings_on_course_id" unless index_exists?(:ta_mappings, :course_id, name: "index_ta_mappings_on_course_id")
    add_index :ta_mappings, :ta_id, name: "fk_ta_mapping_users" unless index_exists?(:ta_mappings, :ta_id, name: "fk_ta_mapping_users")
    add_index :ta_mappings, :ta_id, name: "index_ta_mappings_on_user_id" unless index_exists?(:ta_mappings, :ta_id, name: "index_ta_mappings_on_user_id")
  end
end
  