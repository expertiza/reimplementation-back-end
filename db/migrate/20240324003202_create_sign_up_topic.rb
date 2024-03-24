class CreateSignUpTopic < ActiveRecord::Migration[7.0]
  def up
    create_table :sign_up_topics do |t|
      t.text "topic_name", null: false
      t.integer "assignment_id", default: 0, null: false
      t.integer "max_choosers", default: 0, null: false
      t.text "category"
      t.string "topic_identifier", limit: 10
      t.integer "micropayment", default: 0
      t.integer "private_to"
      t.text "description"
      t.string "link"
      t.index ["assignment_id"], name: "fk_sign_up_categories_sign_up_topics"
      t.index ["assignment_id"], name: "index_sign_up_topics_on_assignment_id"
      t.timestamps
    end
  end
  def down
    drop_table :sign_up_topics
  end
end
