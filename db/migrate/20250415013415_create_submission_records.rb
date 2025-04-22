class CreateSubmissionRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :submission_records do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "type"
      t.string "content"
      t.string "operation"
      t.integer "team_id"
      t.string "user"
      t.integer "assignment_id"
    end
  end
end
