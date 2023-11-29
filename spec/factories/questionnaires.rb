FactoryBot.define do
  # A factory to create a questionnaire for use in tests.
  factory :questionnaire do
    name { "General Knowledge Quiz" }
    instructor
    assignment
    min_question_score { 0 }
    max_question_score { 5 }

    # Nested factory for questions
    transient do
      questions_count { 3 } # You can change the number of questions per questionnaire here
    end

    after(:create) do |questionnaire, evaluator|
      create_list(:question, evaluator.questions_count, questionnaire: questionnaire)
    end
  end

  # Factory for Question
  factory :question do
    txt { "Sample Question" }
    question_type { "multiple_choice" }
    break_before { true }
    correct_answer { "Correct Answer" }
    score_value { 1 }
    questionnaire

    # Nested factory for answers
    after(:create) do |question|
      create(:answer, question: question, answer_text: question.correct_answer, correct: true)
      3.times do
        create(:answer, question: question, correct: false)  # Creating 3 incorrect answers
      end
    end
  end

  # Factory for Answer
  factory :answer do
    answer_text { "Sample Answer" }
    correct { false }
    question
  end
end
