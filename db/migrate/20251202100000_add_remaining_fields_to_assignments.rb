class AddRemainingFieldsToAssignments < ActiveRecord::Migration[8.0]
  def change
    change_table :assignments, bulk: true do |t|
      # Team/mentors
      t.boolean :auto_assign_mentors, default: false, null: false

      # Review/quizzes
      t.boolean :has_quizzes, default: false, null: false
      t.boolean :calibration_for_training, default: false, null: false

      # Deadline flag
      t.boolean :staggered_deadline_assignment, default: false, null: false

      # Tag/visibility/topic flags
      t.boolean :available_to_students, default: false, null: false
      t.boolean :allow_topic_suggestion_from_students, default: false, null: false
      t.boolean :enable_bidding_for_topics, default: false, null: false
      t.boolean :enable_bidding_for_reviews, default: false, null: false
      t.boolean :enable_authors_to_review_other_topics, default: false, null: false
      t.boolean :allow_reviewer_to_choose_topic_to_review, default: false, null: false
      t.boolean :allow_participants_to_create_bookmarks, default: false, null: false
    end
  end
end

