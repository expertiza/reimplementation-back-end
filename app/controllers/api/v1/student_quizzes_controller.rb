class Api::V1::StudentQuizzesController < ApplicationController
  before_action :check_instructor_role, except: [:submit_quiz]
  before_action :set_student_quiz, only: [:show, :update, :destroy]

  # Rescue from ActiveRecord::RecordInvalid exceptions and render an error response
  rescue_from ActiveRecord::RecordInvalid do |exception|
    render_error(exception.message)
  end

  # GET /student_quizzes
  # Fetch and render all quizzes
  def index
    quizzes = Questionnaire.all
    render_success(quizzes)
  end

  # GET /student_quizzes/:id
  # Fetch and render a specific quiz by ID
  def show
    render_success(@student_quiz)
  end

  # GET /student_quizzes/:id/calculate_score
  # Calculate and render the score for a specific quiz attempt
  def calculate_score
    response_map = ResponseMap.find_by(id: params[:id])
    if response_map
      render_success({ score: response_map.calculate_score })
    else
      render_error('Attempt not found or you do not have permission to view this score.', :not_found)
    end
  end

  # POST /student_quizzes
  # Create a new quiz with associated questions and answers
  def create
    questionnaire = ActiveRecord::Base.transaction do
      questionnaire = create_questionnaire(questionnaire_params.except(:questions_attributes))
      create_questions_and_answers(questionnaire, questionnaire_params[:questions_attributes])
      questionnaire
    end
    render_success(questionnaire, :created)
  rescue StandardError => e
    render_error(e.message, :unprocessable_entity)
  end

  # Helper method to create a questionnaire
  # @param params [Hash] the parameters for creating a questionnaire
  # @return [Questionnaire] the created questionnaire
  def create_questionnaire(params)
    Questionnaire.create!(params)
  end

  # POST /student_quizzes/assign
  # Assign a quiz to a student
  def assign_quiz
    participant = find_resource_by_id(Participant, params[:participant_id])
    questionnaire = find_resource_by_id(Questionnaire, params[:questionnaire_id])
    
    # Stop execution if either the participant or questionnaire does not exist
    return unless participant && questionnaire

    # Check if the quiz has already been assigned to this student
    if quiz_already_assigned?(participant, questionnaire)
      render_error("This student is already assigned to the quiz.", :unprocessable_entity)
      return
    end

    # Create a new response map to link the student and the quiz
    response_map = ResponseMap.build_response_map(participant.user_id, questionnaire)
    
    # Attempt to save the response map and render appropriate success or error messages
    if response_map.save
      render_success(response_map, :created)
    else
      render_error(response_map.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  # POST /student_quizzes/submit_answers
  # Submit answers for a quiz and calculate the total score
  def submit_quiz
    ActiveRecord::Base.transaction do
      response_map = find_response_map_for_current_user
      unless response_map
        render_error("You are not assigned to take this quiz.", :forbidden)
        return
      end

      total_score = response_map.process_answers(params[:answers])
      response_map.update!(score: total_score)
      render_success({ total_score: total_score })
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.message, :unprocessable_entity)
  end

  # PUT /student_quizzes/:id
  # Update a specific quiz by ID
  def update
    if @student_quiz.update(questionnaire_params)
      render_success(@student_quiz)
    else
      render_error(@student_quiz.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  # DELETE /student_quizzes/:id
  # Delete a specific quiz by ID
  def destroy
    @student_quiz.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error('Record does not exist', :not_found)
  end

  private

  # Fetch and set the quiz from the database
  # @return [void]
  def set_student_quiz
    @student_quiz = find_resource_by_id(Questionnaire, params[:id])
  end

  # Find the response map for the current user's attempt to submit quiz answers
  # @return [ResponseMap, nil] the response map if found, otherwise nil
  def find_response_map_for_current_user
    ResponseMap.find_by(reviewee_id: current_user.id, reviewed_object_id: params[:questionnaire_id])
  end

  # Find a resource by its ID and handle the case where it is not found
  # @param model [Class] the model class to search
  # @param id [Integer] the ID of the resource
  # @return [Object, nil] the found resource or nil if not found
  def find_resource_by_id(model, id)
    model.find(id)
  rescue ActiveRecord::RecordNotFound
    render_error("#{model.name} not found", :not_found)
    nil
  end

  # Check if the quiz has already been assigned to the student
  # @param participant [Participant] the participant
  # @param questionnaire [Questionnaire] the questionnaire
  # @return [Boolean] true if the quiz is already assigned, false otherwise
  def quiz_already_assigned?(participant, questionnaire)
    ResponseMap.exists?(reviewee_id: participant.user_id, reviewed_object_id: questionnaire.id)
  end

  # Create questions and their respective answers for a questionnaire
  # @param questionnaire [Questionnaire] the questionnaire
  # @param questions_attributes [Array<Hash>] the attributes for the questions
  # @return [void]
  def create_questions_and_answers(questionnaire, questions_attributes)
    questions_attributes.each do |question_attr|
      question = questionnaire.questions.create!(question_attr.except(:answers_attributes))
      question_attr[:answers_attributes]&.each do |answer_attr|
        question.answers.create!(answer_attr)
      end
    end
  end

  # Permit and require the necessary parameters for creating/updating a questionnaire
  # @return [ActionController::Parameters] the permitted parameters
  def questionnaire_params
    params.require(:questionnaire).permit(
      :name, :instructor_id, :min_question_score, :max_question_score, :assignment_id,
      questions_attributes: [:id, :txt, :question_type, :break_before, :correct_answer, :score_value,
                             { answers_attributes: %i[id answer_text correct] }]
    )
  end

  # Render a success response with optional custom status code
  # @param data [Object] the data to render
  # @param status [Symbol] the HTTP status code
  # @return [void]
  def render_success(data, status = :ok)
    render json: data, status: status
  end

  # Render an error response with message and status code
  # @param message [String] the error message
  # @param status [Symbol] the HTTP status code
  # @return [void]
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  # Ensure only instructors can perform certain actions
  # @return [void]
  def check_instructor_role
    unless current_user.role.instructor?
      render_error('Only instructors are allowed to perform this action', :forbidden)
    end
  end
end