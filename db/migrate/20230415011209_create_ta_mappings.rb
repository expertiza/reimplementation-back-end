class CreateTaMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :ta_mappings do |t|
      t.references :course, null: false, foreign_key: true
      t.references :ta, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :ta_mappings, :ta_id, name: "fk_ta_mapping_users"
  end
end
