class CreateResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :responses do |t|
      t.integer "map_id", default: 0, null: false
      t.text "additional_comment"
      t.index ["map_id"], name: "fk_response_response_map"
    end
  end
end
