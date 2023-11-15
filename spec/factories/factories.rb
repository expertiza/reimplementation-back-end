FactoryBot.define do

  factory :participant, class: AssignmentParticipant do
    assignment { Assignment.first || association(:assignment) }
    association :user, factory: :student
  end

  factory :course_participant, class: CourseParticipant do
    course { Course.first || association(:course) }
    association :user, factory: :student
    type 'CourseParticipant'
    handle 'handle'
  end

  factory :assignment, class: Assignment do
    # Help multiple factory-created assignments get unique names
    # Let the first created assignment have the name 'final2' to avoid breaking some fragile existing tests
    name { (Assignment.last ? ('assignment' + (Assignment.last.id + 1).to_s) : 'final2').to_s }
    directory_path 'final_test'
    submitter_count 0
    course { Course.first || association(:course) }
    instructor { Instructor.first || association(:instructor) }
    private false
    num_reviews 1
    num_review_of_reviews 1
    num_review_of_reviewers 1
    reviews_visible_to_all false
    num_reviewers 1
    spec_location 'https://expertiza.ncsu.edu/'
    max_team_size 3
    staggered_deadline false
    allow_suggestions false
    review_assignment_strategy 'Auto-Selected'
    max_reviews_per_submission 2
    review_topic_threshold 0
    copy_flag false
    rounds_of_reviews 2
    microtask false
    require_quiz false
    num_quiz_questions 0
    is_coding_assignment false
    is_intelligent false
    calculate_penalty false
    late_policy_id nil
    is_penalty_calculated false
    show_teammate_reviews true
    availability_flag true
    use_bookmark false
    can_review_same_topic true
    can_choose_topic_to_review true
    num_reviews_required 3
    num_metareviews_required 3
    num_reviews_allowed 3
    num_metareviews_allowed 3
    is_calibrated false
    has_badge false
    allow_selecting_additional_reviews_after_1st_round false
  end

  factory :student, class: User do
    # Zhewei: In order to keep students the same names (2065, 2066, 2064) before each example.
    sequence(:name) { |n| n = n % 3; "student206#{n + 4}" }
    role { Role.where(name: 'Student').first || association(:role_of_student) }
    password 'password'
    sequence(:fullname) { |n| n = n % 3; "206#{n + 4}, student" }
    email 'expertiza@mailinator.com'
    parent_id 1
    mru_directory_path  nil
    email_on_review true
    email_on_submission true
    email_on_review_of_review true
    is_new_user false
    master_permission_granted 0
    handle 'handle'
    public_key nil
    copy_of_emails false
  end

  factory :course, class: Course do
    sequence(:name) { |n| "CSC517, test#{n}" }
    instructor { Instructor.first || association(:instructor) }
    directory_path 'csc517/test'
    info 'Object-Oriented Languages and Systems'
    private true
  end
end