FactoryBot.define do
  factory :assignment, class: Assignment do
    # Help multiple factory-created assignments get unique names
    # Let the first created assignment have the name 'final2' to avoid breaking some fragile existing tests
    name { (Assignment.last ? "assignment#{Assignment.last.id + 1}" : 'final2').to_s }
    directory_path { 'final_test' }
    submitter_count { 0 }
    private { false }
    num_reviews { 1 }
    num_review_of_reviews { 1 }
    num_review_of_reviewers { 1 }
    reviews_visible_to_all { false }
    num_reviewers { 1 }
    spec_location { 'https://expertiza.ncsu.edu/' }
    max_team_size { 3 }
    staggered_deadline { false }
    allow_suggestions { false }
    days_between_submissions { 1 }
    review_assignment_strategy { 'Auto-Selected' }
    max_reviews_per_submission { 2 }
    review_topic_threshold { 0 }
    copy_flag { false }
    rounds_of_reviews { 2 }
    # vary_by_round? { false }
    # vary_by_topic? { false }
    microtask { false }
    require_quiz { false }
    num_quiz_questions { 0 }
    is_coding_assignment { false }
    is_intelligent { false }
    calculate_penalty { false }
    late_policy_id { nil }
    is_penalty_calculated { false }
    max_bids { 1 }
    show_teammate_reviews { true }
    availability_flag { true }
    use_bookmark { false }
    can_review_same_topic { true }
    can_choose_topic_to_review { true }
    is_calibrated { false }
    is_selfreview_enabled { false }
    reputation_algorithm { 'Lauw' } # Check if valid
    is_anonymous { false }
    num_reviews_required { 3 }
    num_metareviews_required { 3 }
    num_reviews_allowed { 3 }
    num_metareviews_allowed { 3 }
    simicheck { 0 }
    simicheck_threshold { 0 }
    is_answer_tagging_allowed { false }
    has_badge { false }
    allow_selecting_additional_reviews_after_1st_round { false }
    sample_assignment_id { nil }
    instructor_id do
      User.find_by(role: Role.find_by(name: 'Instructor'))&.id ||
        association(:user, role: association(:role, name: 'Instructor')).id
    end
    course { Course.first || association(:course) }
    instructor { Instructor.first || association(:instructor) }
  end

  factory :assignment_team, class: AssignmentTeam do
  end

  factory :response, class: Response do
    map { ReviewResponseMap.first || association(:review_response_map) }
    additional_comment { nil }
  end

  factory :signed_up_team, class: SignedUpTeam do
    topic { SignUpTopic.first || association(:topic) }
    team_id { 1 }
    is_waitlisted { false }
    preference_priority_number { nil }
  end

  factory :participant, class: AssignmentParticipant do
    association :user, factory: :user
    assignment { Assignment.first || association(:assignment) }
    can_review { true }
    can_submit { true }
    handle { 'handle' }
    join_team_request_id { nil }
    team_id { nil }
    topic { nil }
    current_stage { nil }
    stage_deadline { nil }
  end

  # factory :questionnaire, class: ReviewQuestionnaire do
  #   name 'Test questionnaire'
  #   # Beware: it is fragile to assume that role_id of instructor is 1 (or any other unchanging value)
  #   instructor { Instructor.first || association(:instructor) }
  #   private 0
  #   min_question_score 0
  #   max_question_score 5
  #   type 'ReviewQuestionnaire'
  #   display_type 'Review'
  #   instruction_loc nil
  # end

  factory :review_response_map, class: ReviewResponseMap do
    assignment { Assignment.first || association(:assignment) }
    reviewer { AssignmentParticipant.first || association(:participant) }
    reviewee { AssignmentTeam.first || association(:assignment_team) }
    type { 'ReviewResponseMap' }
    calibrate_to { 0 }
  end

  factory :feedback_response_map, class: FeedbackResponseMap do
    type { 'FeedbackResponseMap' }
    calibrate_to { 0 }
  end

  factory :course do
    sequence(:name) { |n| "Course #{n}" }
    sequence(:directory_path) { |n| "/course_#{n}/" }

    # Search the database for someone with the instructor role
    instructor_id do
      User.find_by(role: Role.find_by(name: 'Instructor'))&.id ||
        association(:user, role: association(:role, name: 'Instructor')).id
    end

    # Use the existing 'North Carolina State University' institution if available
    institution_id do
      Institution.find_by(name: 'North Carolina State University')&.id ||
        association(:institution, name: 'North Carolina State University').id
    end
  end

  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }
  end

  factory :role do
    id { Role.find_by(name: 'Student').id || 5 }
    name { 'Student' }
  end
end
