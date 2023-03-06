class CreateAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :assignments, on_delete: :cascade do |t|
      t.string :name
      t.string :directory_path
      t.integer :submitter_count
      t.integer :course_id
      t.integer :instructor_id
      t.boolean :private
      t.integer :num_reviews
      t.integer :num_review_of_reviews
      t.integer :num_review_of_reviewers
      t.boolean :reviews_visible_to_all
      t.integer :num_reviewers
      t.text :spec_location
      t.integer :max_team_size
      t.boolean :staggered_deadline
      t.boolean :allow_suggestions
      t.integer :days_between_submissions
      t.string :review_assignment_strategy
      t.integer :max_reviews_per_submission
      t.integer :review_topic_threshold
      t.boolean :copy_flag
      t.integer :rounds_of_reviews
      t.boolean :microtask
      t.boolean :require_quiz
      t.integer :num_quiz_questions
      t.boolean :is_coding_assignment
      t.boolean :is_intelligent
      t.boolean :calculate_penalty
      t.integer :late_policy_id
      t.boolean :is_penalty_calculated
      t.integer :max_bids
      t.boolean :show_teammate_reviews
      t.boolean :availability_flag
      t.boolean :use_bookmark
      t.boolean :can_review_same_topic
      t.boolean :can_choose_topic_to_review
      t.boolean :is_calibrated
      t.boolean :is_selfreview_enabled
      t.string :reputation_algorithm
      t.boolean :is_anonymous
      t.integer :num_reviews_required
      t.integer :num_metareviews_required
      t.integer :num_metareviews_allowed
      t.integer :num_reviews_allowed
      t.integer :simicheck
      t.integer :simicheck_threshold
      t.boolean :is_answer_tagging_allowed
      t.boolean :has_badge
      t.boolean :allow_selecting_additional_reviews_after_1st_round
      t.integer :sample_assignment_id

      t.timestamps
    end
  end
end
