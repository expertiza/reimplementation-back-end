class CreateDueDates < ActiveRecord::Migration[7.0]
  def change
    create_table :due_dates do |t|
      t.datetime :due_at, null: false
      t.integer :deadline_type_id, null: false
      t.references :parent_id, null: false, polymorphic: true
      t.integer :submission_allowed_id, null: false
      t.integer :review_allowed_id, null: false
      t.integer :resubmission_allowed_id
      t.integer :rereview_allowed_id
      t.integer :review_of_review_allowed_id
      t.integer :round
      t.integer :threshold
      t.integer :teammate_review_allowed_id, default: 3

      # I believe the rest of these are no longer used, but still necessary for backwards compatability?
      t.boolean :flag, default: false
      t.integer :delayed_job_id
      t.string :deadline_name
      t.string :description_url
      t.integer :quiz_allowed_id, default: 1
      t.string :type, default: "AssignmentDueDate"  # This might still be used but I think we should be able pull it from the parent instead of manually setting it
      
      t.timestamps
    end
  end
end
