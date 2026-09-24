# frozen_string_literal: true

class CreateReviewGrades < ActiveRecord::Migration[7.0]
  def change
    create_table :review_grades, if_not_exists: true do |t|
      t.bigint   :participant_id, null: false, index: { unique: true }
      t.float    :grade_for_reviewer
      t.text     :comment_for_reviewer
      t.integer  :grader_id

      t.timestamps
    end
  end
end
