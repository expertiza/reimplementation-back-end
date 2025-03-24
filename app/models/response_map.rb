class ResponseMap < ApplicationRecord
  # 'reviewer_id' points to the User who is the instructor.
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :questionnaire, foreign_key: 'reviewed_object_id', optional: true
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  validates :reviewee_id, uniqueness: { scope: :reviewed_object_id, message: "is already assigned to this questionnaire" }

  # Gets the score from this response map
  def calculate_score
    responses.sum do |response|
      question = response.question
      skipped = response.skipped
      next 0 if skipped
      question.correct_answer == response.submitted_answer ? question.score_value : 0
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

  def self.find_for_current_user(user, questionnaire_id)
    find_by(
      reviewee_id: user.id,
      reviewed_object_id: questionnaire_id
    )
  end

  # # Returns the assignment related to the response map
  # def response_assignment
  #   assignment
  # end

  private

  def find_or_initialize_response(response_map_id, question_id)
    Response.find_or_initialize_by(response_map_id: response_map_id, question_id: question_id)
  end


end