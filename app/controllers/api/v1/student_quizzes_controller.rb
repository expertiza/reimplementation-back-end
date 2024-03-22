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

  # POST /student_quizzes/assign
  def assign_quiz_to_student
    participant = find_participant(params[:participant_id])
    questionnaire = find_questionnaire(params[:questionnaire_id])

    if quiz_already_assigned?(participant, questionnaire)
      render json: { error: "This student is already assigned to the quiz." }, status: :unprocessable_entity
      return
    end

    response_map = build_response_map(participant.user_id, questionnaire)

    if response_map.save
      # Handle success, render a success message or the response_map itself
    else
      render json: { error: response_map.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_participant(id)
    Participant.find(id)
  end

  def find_questionnaire(id)
    Questionnaire.find(id)
  end

  def quiz_already_assigned?(participant, questionnaire)
    ResponseMap.exists?(
      reviewee_id: participant.user_id,
      reviewed_object_id: questionnaire.id
    )
  end

  def build_response_map(student_id, questionnaire)
    instructor_id = find_instructor_id_for_questionnaire(questionnaire)
    ResponseMap.new(
      reviewee_id: student_id,
      reviewer_id: instructor_id,
      reviewed_object_id: questionnaire.id
    )
  end

  def find_instructor_id_for_questionnaire(questionnaire)
    Assignment.find(questionnaire.assignment_id).instructor_id
  end

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
    return if current_user.role_id == 1

    render json: { error: 'Only instructors are allowed to perform this action' }, status: :forbidden
    nil
  end

end
