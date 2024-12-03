class ResponseMap < ApplicationRecord
  # 'reviewer_id' points to the User who is the instructor.
  belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewer_id', optional: true
  belongs_to :reviewee, class_name: 'User', foreign_key: 'reviewee_id', optional: true
  belongs_to :questionnaire, foreign_key: 'reviewed_object_id', optional: true
  has_many :responses
  validates :reviewee_id, uniqueness: { scope: :reviewed_object_id,
                                        message: "is already assigned to this questionnaire" }

  def calculate_score
    render_success({ score: self.score })
  end

  def process_answers(answers)
    answers.sum do |answer|
      question = Question.find(answer[:question_id])
      submitted_answer = answer[:answer_value]

      response = find_or_initialize_response(self.id, question.id)
      response.submitted_answer = submitted_answer
      response.save!

      question.correct_answer == submitted_answer ? question.score_value : 0
    end
  end
end