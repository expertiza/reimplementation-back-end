FactoryBot.define do
  factory :questionnaire do
    name {'abc'}
    private {0}
    min_question_score {0}
    max_question_score {5}
  end

  factory :question do
    type {'Dropdown'}
    weight {2}
  end

  factory :questionnaire_node do
  end

  factory :assignment do
  end

  factory :assignment_questionnaire do
    used_in_round nil
  end
end

