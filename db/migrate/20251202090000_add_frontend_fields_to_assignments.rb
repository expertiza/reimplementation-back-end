class AddFrontendFieldsToAssignments < ActiveRecord::Migration[8.0]
  def change
    change_table :assignments, bulk: true do |t|
      # Base / flags
      t.boolean :show_template_review, default: false, null: false

      # Team-related
      t.boolean :show_teammate_review, default: false, null: false
      t.boolean :is_pair_programming, default: false, null: false
      t.boolean :has_mentors, default: false, null: false
      t.boolean :auto_assign_mentors, default: false, null: false

      # Review-related
      t.integer :maximum_number_of_reviews_per_submission
      t.string  :review_strategy
      t.boolean :review_rubric_varies_by_round, default: false, null: false
      t.boolean :review_rubric_varies_by_topic, default: false, null: false
      t.boolean :review_rubric_varies_by_role,  default: false, null: false
      t.boolean :has_max_review_limit, default: false, null: false
      t.integer :set_allowed_number_of_reviews_per_reviewer
      t.integer :set_required_number_of_reviews_per_reviewer
      t.boolean :is_review_anonymous, default: false, null: false
      t.boolean :is_review_done_by_teams, default: false, null: false
      t.boolean :allow_self_reviews, default: false, null: false
      t.boolean :reviews_visible_to_other_reviewers, default: false, null: false
      t.integer :number_of_review_rounds
      t.boolean :has_quizzes, default: false, null: false
      t.boolean :calibration_for_training, default: false, null: false

      # Deadline flags
      t.boolean :use_signup_deadline, default: false, null: false
      t.boolean :use_drop_topic_deadline, default: false, null: false
      t.boolean :use_team_formation_deadline, default: false, null: false
      t.boolean :staggered_deadline_assignment, default: false, null: false

      # Arrays / JSON fields
      t.json :weights
      t.json :notification_limits
      t.json :use_date_updater
      t.json :submission_allowed
      t.json :review_allowed
      t.json :teammate_allowed
      t.json :metareview_allowed
      t.json :reminder

      # Tag prompts / availability and topic-related flags
      t.boolean :allow_tag_prompts, default: false, null: false
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


