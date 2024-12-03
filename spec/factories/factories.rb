FactoryBot.define do
    
  
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
  
  
#     factory :assignment_team, class: AssignmentTeam do
#       sequence(:name) { |n| "team#{n}" }
#       assignment { Assignment.first || association(:assignment) }
#       type 'AssignmentTeam'
#       comments_for_advertisement nil
#       advertise_for_partner nil
#       submitted_hyperlinks '---
#   - https://www.expertiza.ncsu.edu'
#       directory_num 0
#     end
  
  
  
    
  
    factory :signed_up_team, class: SignedUpTeam do
      topic { SignUpTopic.first || association(:topic) }
      team_id { 1 }
      is_waitlisted { false }
      preference_priority_number { nil }
    end
  
    factory :participant, class: AssignmentParticipant do
      can_submit { true }
      can_review { true }
      assignment { Assignment.first || association(:assignment) }
      association :user, factory: :student
      submitted_at { nil }
      permission_granted { nil }
      penalty_accumulated { 0 }
      grade { nil }
      type { 'AssignmentParticipant' }
      handle { 'handle' }
      time_stamp { nil }
      digital_signature { nil }
      can_mentor { false }
      can_take_quiz { true }
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
  
  
  
  
  end
