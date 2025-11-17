# frozen_string_literal: true

class CreateResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :responses, on_delete: :cascade do |t|
      t.integer "map_id", default: 0, null: false
      t.text "additional_comment"
      t.boolean "is_submitted", default: false
      t.index ["map_id"], name: "fk_response_response_map"

      t.timestamps
    end
  end
end
