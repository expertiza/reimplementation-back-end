class Api::V1::StudentQuizzesController < ApplicationController
  before_action :check_instructor_role, except: [:submit_answers]
  before_action :set_student_quiz, only: [:show, :edit, :update, :destroy]
  def index
    @quizzes = Questionnaire.all
    render json: @quizzes
  end

  # GET /student_quizzes/:id
  def show
    render json: @student_quiz
  end

  # GET /student_quizzes/:id/calculate_score
  def calculate_score
    # Find the ResponseMap by its ID.
    # Make sure this ID is the ID of the ResponseMap, not the Questionnaire or the Participant.
    response_map = ResponseMap.find_by(id: params[:id])

    if response_map
      # Return the score of the ResponseMap
      render json: { score: response_map.score }, status: :ok
    else
      render json: { error: 'Attempt not found or you do not have permission to view this score.' }, status: :not_found
    end
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

  # POST /student_quizzes/submit_answers
  # Method to submit answers for a quiz
  def submit_answers
    ActiveRecord::Base.transaction do
      response_map = find_response_map_for_current_user

      # Return error if no ResponseMap exists for the current user
      unless response_map
        render json: { error: "You are not assigned to take this quiz." }, status: :forbidden
        return
      end

      total_score = process_answers(params[:answers], response_map)

      # Update the score of the ResponseMap with the total score from answers
      response_map.update!(score: total_score)

      # Respond with the total score calculated from the submitted answers
      render json: { total_score: total_score }, status: :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH/PUT /student_quizzes/:id
  def update
    if @student_quiz.update(questionnaire_params)
      render json: @student_quiz
    else
      render json: @student_quiz.errors, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /student_quizzes/:id
  def destroy
    @student_quiz.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Record does not exist' }, status: :no_content
  end


  private

  # New method to permit parameters for submitting answers
  def response_map_params
    params.require(:response_map).permit(:student_id, :questionnaire_id)
  end

  def set_student_quiz
    @student_quiz = Questionnaire.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Record does not exist' }, status: :no_content
  end

  # Find the existing ResponseMap for the current user and the questionnaire
  def find_response_map_for_current_user
    ResponseMap.find_by(
      reviewee_id: current_user.id,
      reviewed_object_id: params[:questionnaire_id]
    )
  end

  # Process each submitted answer, calculate total score
  def process_answers(answers, response_map)
    answers.sum do |answer|
      process_answer(answer, response_map)
    end
  end

  # Process a single answer, return score value
  def process_answer(answer, response_map)
    question = Question.find(answer[:question_id])
    submitted_answer = answer[:answer_value]

    response = find_or_initialize_response(response_map.id, question.id)
    response.submitted_answer = submitted_answer
    response.save!

    # Return the question's score value if the answer is correct, otherwise return 0
    question.correct_answer == submitted_answer ? question.score_value : 0
  end

  # Find or initialize a response for the given response_map_id and question_id
  def find_or_initialize_response(response_map_id, question_id)
    Response.find_or_initialize_by(
      response_map_id: response_map_id,
      question_id: question_id
    )
  end

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
    return if current_user.role_id == 3

    render json: { error: 'Only instructors are allowed to perform this action' }, status: :forbidden
    nil
  end

end
