class CreateDueDates < ActiveRecord::Migration[7.0]
  def change
    create_table :due_dates do |t|
      t.datetime :due_at, null: false
      t.integer :deadline_type_id, null: false
      t.references :parent, null: false, polymorphic: true
      t.integer :submission_allowed_id, null: false
      t.integer :review_allowed_id, null: false
      t.integer :round
      t.boolean :flag, default: false
      t.integer :threshold, default: 1
      t.string :delayed_job_id
      t.string :deadline_name
      t.string :description_url
      t.integer :quiz_allowed_id, default: 1
      t.integer :teammate_review_allowed_id, default: 3
      t.string :type, default: "AssignmentDueDate"
      t.integer :resubmission_allowed_id
      t.integer :rereview_allowed_id
      t.integer :review_of_review_allowed_id

      t.timestamps
    end
  end
end
