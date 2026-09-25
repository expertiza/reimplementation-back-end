class AssignmentSerializer < ActiveModel::Serializer
  attributes :id, :name, :course_id,
             # General tab
             :directory_path, :spec_location, :private,
             :require_quiz, :has_badge, :staggered_deadline, :is_calibrated,
             :has_teams, :max_team_size,
             :show_teammate_review, :is_pair_programming,
             :has_topics,
             :allow_tag_prompts, :available_to_students,
             :allow_participants_to_create_bookmarks,
             # Mentors
             :has_mentors, :auto_assign_mentors,
             :staggered_deadline_assignment,
             # Topics / bidding
             :allow_topic_suggestion_from_students,
             :enable_bidding_for_topics,
             :enable_bidding_for_reviews,
             :enable_authors_to_review_other_topics,
             :allow_reviewer_to_choose_topic_to_review,
             # Review strategy tab
             :review_topic_threshold, :maximum_number_of_reviews_per_submission,
             :review_strategy,
             :review_rubric_varies_by_round,
             :review_rubric_varies_by_topic, :review_rubric_varies_by_role,
             :is_review_anonymous, :allow_self_reviews,
             :reviews_visible_to_other_reviewers,
             :is_review_done_by_teams,
             :is_role_based,
             :set_allowed_number_of_reviews_per_reviewer,
             :set_required_number_of_reviews_per_reviewer,
             :number_of_review_rounds,
             :instructor_grade_min_score, :instructor_grade_max_score,
             # Due dates tab
             :days_between_submissions, :late_policy_id,
             :is_penalty_calculated, :calculate_penalty

  has_many :due_dates, serializer: DueDateSerializer
  has_many :assignment_questionnaires, serializer: AssignmentQuestionnaireSerializer
end
