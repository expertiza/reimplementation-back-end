class CreateVersions < ActiveRecord::Migration[8.0]
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :versions, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" do |t|
      t.string   :whodunnit

      t.datetime :created_at

      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false, limit: 191
      t.string   :event,     null: false
      t.text     :object, limit: TEXT_BYTES
    end
    add_index :versions, %i[item_type item_id]
  end
end
