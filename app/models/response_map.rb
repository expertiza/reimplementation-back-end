class ResponseMap < ApplicationRecord
  # 'reviewer_id' points to the User who is the instructor.
  belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewer_id', optional: true
  belongs_to :reviewee, class_name: 'User', foreign_key: 'reviewee_id', optional: true
  belongs_to :questionnaire, foreign_key: 'reviewed_object_id', optional: true
  has_many :responses
  validates :reviewee_id, uniqueness: { scope: :reviewed_object_id, message: "is already assigned to this questionnaire" }

  # Gets the score from this response map
  def calculate_score
    responses.sum do |response|
      question = response.question
      response.skipped ? 0 : (question.correct_answer == response.submitted_answer ? question.score_value : 0)
    end
  end

  def get_score
    self.score
  end

  # Save the submitted answers and check if that answer is correct
  def process_answers(answers)
    answers.sum do |answer|
      question = Question.find(answer[:question_id])
      submitted_answer = answer[:answer_value]
      skipped = answer[:skipped] || false

      puts "#{skipped}"
      puts "#{question.skippable}"
      if skipped && !question.skippable
        raise ActiveRecord::RecordInvalid.new("Question #{question.id} cannot be skipped.")
      end

      response = find_or_initialize_response(self.id, question.id)
      response.submitted_answer = submitted_answer
      response.is_submitted = true
      response.skipped = skipped
      response.save!

      skipped ? 0 : (question.correct_answer == submitted_answer ? question.score_value : 0)
    end
  end

  # Build a new ResponseMap instance for assigning a quiz to a student
  def self.build_response_map(student_id, questionnaire)
    instructor_id = questionnaire.assignment.instructor_id
    ResponseMap.new(
      reviewee_id: student_id,
      reviewer_id: instructor_id,
      reviewed_object_id: questionnaire.id
    )
  end

  private

  def find_or_initialize_response(response_map_id, question_id)
    Response.find_or_initialize_by(response_map_id: response_map_id, question_id: question_id)
  end
end