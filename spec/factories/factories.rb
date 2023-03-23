FactoryBot.define do
  factory :questionnaire do
    name {'abc'}
    private {0}
    min_question_score {0}
    max_question_score {5}
  end

  factory :question do
    questionnaire { Questionnaire.first || association(:questionnaire) }
    type {'Dropdown'}
    weight {2}
  end

  factory :question_advice, class: QuestionAdvice do
    question { Question.first || association(:question) }
    score 5
    advice 'LGTM'
  end

  factory :questionnaire_node do
  end

  factory :assignment do
  end

end

