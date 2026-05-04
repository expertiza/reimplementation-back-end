class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :name, :directory_path, :submitter_count, :private,
             :num_reviews, :num_review_of_reviews, :num_review_of_reviewers,
             :reviews_visible_to_all, :num_reviewers, :spec_location,
             :max_team_size, :staggered_deadline, :allow_suggestions,
             :days_between_submissions, :review_assignment_strategy,
             :max_reviews_per_submission, :review_topic_threshold,
             :rounds_of_reviews, :require_quiz, :num_quiz_questions,
             :calculate_penalty, :late_policy_id, :is_penalty_calculated,
             :max_bids, :show_teammate_reviews, :availability_flag,
             :use_bookmark, :can_review_same_topic, :can_choose_topic_to_review,
             :is_calibrated, :is_selfreview_enabled, :is_anonymous,
             :num_reviews_required, :num_metareviews_required,
             :num_metareviews_allowed, :num_reviews_allowed,
             :has_badge, :sample_assignment_id, :instructor_id, :course_id,
             :enable_pair_programming, :has_teams, :has_topics, :vary_by_round,
             :created_at, :updated_at

  has_many :assignment_questionnaires
  has_many :questionnaires
  has_many :due_dates
end
