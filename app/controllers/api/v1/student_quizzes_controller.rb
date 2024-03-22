class Api::V1::StudentQuizzesController < ApplicationController
  before_action :check_instructor_role
  def index
    @quizzes = Questionnaire.all
    render json: @quizzes
  end

  # POST /student_quizzes/create_questionnaire
  def create_questionnaire
    # Wrap the entire questionnaire creation process in a transaction
    # to ensure data integrity. All changes are rolled back if any part fails.
    ActiveRecord::Base.transaction do
      # Create the questionnaire without the nested questions to avoid deep nesting issues.
      questionnaire = Questionnaire.create!(questionnaire_params.except(:questions_attributes))

      # Iterate over each question within the questionnaire
      questionnaire_params[:questions_attributes].each do |question_attributes|
        # Create individual questions for the questionnaire,
        # excluding the answers to simplify the creation process.
        question = questionnaire.questions.create!(question_attributes.except(:answers_attributes))

        # Iterate over each answer for the current question
        question_attributes[:answers_attributes].each do |answer_attributes|
          # Create answers for the question
          question.answers.create!(answer_attributes)
        end
      end
    end
  rescue StandardError => e
    # If an error occurs at any point in the process, catch it and render a JSON error response
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def questionnaire_params
    params.require(:questionnaire).permit(
      :name, :instructor_id, :min_question_score, :max_question_score, :assignment_id,
      questions_attributes: [:id, :txt, :question_type, :break_before, :correct_answer, :score_value,
                             { answers_attributes: %i[id answer_text correct] }
      ]
    )
  end

  # Check for instructor
  def check_instructor_role
    return if current_user.role_id == 3

    render json: { error: 'Only instructors are allowed to perform this action' }, status: :forbidden
    nil
  end

end
