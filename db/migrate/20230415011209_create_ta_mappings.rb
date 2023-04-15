class CreateTaMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :ta_mappings do |t|
      t.references :course, null: false, foreign_key: true
      t.integer :ta_id

      t.timestamps
    end
  end
end
