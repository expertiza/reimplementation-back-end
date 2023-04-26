
FactoryBot.define do
  factory :questionnaire_type_node, class: QuestionnaireTypeNode do
    node_object_id {1}
    name {"test"}
    type { "QuestionnaireTypeNode"}
  end
  factory :role_of_teaching_assistant, class: Role do
    name {'Teaching Assistant'}
    parent_id {nil}
    # description {''}
  end
  factory :teaching_assistant, class: Ta do
    name {'teaching_assistant5888'}
    role { Role.where(name: 'Teaching Assistant').first || association(:role_of_teaching_assistant) }
    password {'password'}
    password_confirmation {'password'}
    fullname {'5888, teaching assistant'}
    email {'expertiza@mailinator.com'}
    parent_id {1}
    #private_by_default  {false}
    mru_directory_path  {nil}
    email_on_review {true}
    email_on_submission {true}
    email_on_review_of_review {true}
    is_new_user {false}
    master_permission_granted {0}
    handle {'handle'}
    #digital_certificate {nil}
    timezonepref {'Eastern Time (US & Canada)'}
    #public_key {nil}
    copy_of_emails  {false}
  end
  factory :questionnaire_node, class: QuestionnaireNode do
    parent_id {0}
    node_object_id {0}
    type {'QuestionnaireNode'}
  end
  factory :questionnaire, class: ReviewQuestionnaire do
    name {'Test questionnaire'}
    # Beware: it is fragile to assume that role_id of instructor is 1 (or any other unchanging value)
    instructor { Instructor.first || association(:instructor) }
    private {0}
    min_question_score {0}
    max_question_score {5}
    # type {'ReviewQuestionnaire'}
    # display_type {'Review'}
    # instruction_loc {nil}
  end
  factory :team_node, class: TeamNode do
    node_object_id {1}
    name {"test"}
  end
  factory :course_node, class: CourseNode do
    course { Course.first  }
    node_object_id {1}
    type {'CourseNode'}
  end

  factory :teams_user, class: TeamsUser do
    id{1}
    user_id {1}
  end

  factory :tree_folder, class: TreeFolder do
    id{1}
    user_id {1}
    name {"test"}
  end

  factory :team, class: Team do
      id{1}
  end


  factory :team_user_node, class: TeamUserNode do
      id {1}
      node_object_id {1}
      name {"test"}
      
    end

    factory :course, class: Course do
      # sequence(:name) { |n| "CSC517, test#{n}" }
      instructor { Instructor.first || association(:instructor) }
      # directory_path {'csc517/test'}
      info {'Object-Oriented Languages and Systems'}
      survey_distribution_id { 1 }
      institutions_id { 1 }
      private {true}
      #institutions_id {nil}
    end

    factory :assignment, class: Assignment do
        # Help multiple factory-created assignments get unique names
        # Let the first created assignment have the name 'final2' to avoid breaking some fragile existing tests
      name { (Assignment.last ? ('assignment' + (Assignment.last.id + 1).to_s) : 'final2').to_s }
        directory_path { 'final_test' }
        submitter_count { 0 }
        course { Course.first || association(:course) }
        instructor { Instructor.first || association(:instructor) }
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
        review_assignment_strategy { 'Auto-Selected' }
        max_reviews_per_submission { 2 }
        review_topic_threshold { 0 }
        copy_flag { false }
        rounds_of_reviews { 2 }
        vary_by_round? { false }
        vary_by_topic? { false }
        microtask { false }
        require_quiz { false }
        num_quiz_questions { 0 }
        is_coding_assignment { false }
        is_intelligent { false }
        calculate_penalty { false }
        late_policy_id { nil }
        is_penalty_calculated { false }
        show_teammate_reviews { true }
        availability_flag { true }
        use_bookmark { false }
        can_review_same_topic { true }
        can_choose_topic_to_review { true }
        num_reviews_required { 3 }
        num_metareviews_required { 3 }
        num_reviews_allowed { 3 }
        num_metareviews_allowed { 3 }
        is_calibrated { false }
        has_badge { false }
        allow_selecting_additional_reviews_after_1st_round { false }
        auto_assign_mentor { false }
    end
    factory :instructor, class: Instructor do
      name {'instructor6'}
        #role { Role.where(name: 'Instructor').first || association(:role_of_instructor) }
        password {'password'}
        password_confirmation {'password'}
        fullname {'6, instructor'}
        email {'expertiza@mailinator.com'}
        parent_id {1}
        # private_by_default  {false}
        mru_directory_path  {nil}
        email_on_review {true}
        email_on_submission {true}
        email_on_review_of_review {true}
        is_new_user {false}
        master_permission_granted {0}
        handle {'handle'}
        #digital_certificate {nil}
        timezonepref {'Eastern Time (US & Canada)'}
        #public_key {nil}
        copy_of_emails {false}
    end


end
