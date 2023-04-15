class AddIndexToTaMappings < ActiveRecord::Migration[7.0]
  def change
    add_index :ta_mappings, :ta_id, name: "fk_ta_mapping_users"
  end
end
