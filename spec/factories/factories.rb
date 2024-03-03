FactoryBot.define do
  factory :questionnaire do
    name { 'Valid Name' }
    instructor_id { 0 }
    private { 0 }
    min_question_score { 0 }
    max_question_score { 10 }
    questionnaire_type { 'Valid Type' }
    display_type { 'Valid Display Type' }
    instruction_loc { "Valid Instruction Loc" }
  end
end

