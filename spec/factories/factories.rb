FactoryBot.define do
  factory :questionnaire, class: Questionnaire do
    name { 'Valid Name' }
    instructor_id { 0 }
    private { 0 }
    min_question_score { 0 }
    max_question_score { 10 }
    questionnaire_type { 'Valid Type' }
    display_type { 'Valid Display Type' }
    instruction_loc { "Valid Instruction Loc" }
  end
  factory :review_questionnaire, class: ReviewQuestionnaire do
    name { 'Valid Name' }
    instructor_id { 0 }
    private { 0 }
    min_question_score { 0 }
    max_question_score { 10 }
    questionnaire_type { 'Valid Type' }
    display_type { 'Valid Display Type' }
    instruction_loc { "Valid Instruction Loc" }
  end
  factory :assignment_questionnaire, class: AssignmentQuestionnaire do
    questionnaire_weight { 100 }
    used_in_round { nil }
  end
end

