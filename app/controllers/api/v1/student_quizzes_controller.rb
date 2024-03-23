class Api::V1::StudentQuizzesController < ApplicationController
  # Ensure only instructors can access most actions
  before_action :check_instructor_role, except: [:submit_answers]
  # Set the student quiz for actions that operate on a specific quiz
  before_action :set_student_quiz, only: [:show, :update, :destroy]

  # Handle common ActiveRecord validation failures across actions
  rescue_from ActiveRecord::RecordInvalid do |exception|
    render_error(exception.message)
  end

  # Lists all questionnaires (quizzes)
  def index
    quizzes = Questionnaire.all
    render_success(quizzes)
  end

  # Show a specific student quiz
  def show
    render_success(@student_quiz)
  end

  # Calculate and show the score for a specific attempt
  def calculate_score
    response_map = ResponseMap.find_by(id: params[:id])
    if response_map
      render_success({ score: response_map.score })
    else
      render_error('Attempt not found or you do not have permission to view this score.', :not_found)
    end
  end

  # Create a new questionnaire with questions and answers
  def create
    questionnaire = ActiveRecord::Base.transaction do
      questionnaire = create_questionnaire(questionnaire_params.except(:questions_attributes))
      create_questions_and_answers(questionnaire, questionnaire_params[:questions_attributes])
      questionnaire # Ensure questionnaire is returned from the transaction block
    end
    render_success(questionnaire)
  rescue StandardError => e
    render_error(e.message, :unprocessable_entity)
  end


  # Assign a quiz to a student
  def assign_quiz_to_student
    participant = find_resource_by_id(Participant, params[:participant_id])
    questionnaire = find_resource_by_id(Questionnaire, params[:questionnaire_id])
    return unless participant && questionnaire

    if quiz_already_assigned?(participant, questionnaire)
      render_error("This student is already assigned to the quiz.", :unprocessable_entity)
      return
    end

    response_map = build_response_map(participant.user_id, questionnaire)
    if response_map.save
      render_success(response_map)
    else
      render_error(response_map.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  # Submit answers for a quiz and calculate the total score
  def submit_answers
    ActiveRecord::Base.transaction do
      response_map = find_response_map_for_current_user
      unless response_map
        render_error("You are not assigned to take this quiz.", :forbidden)
        return
      end

      total_score = process_answers(params[:answers], response_map)
      response_map.update!(score: total_score)
      render_success({ total_score: total_score })
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.message, :unprocessable_entity)
  end

  # Update a student quiz
  def update
    if @student_quiz.update(questionnaire_params)
      render_success(@student_quiz)
    else
      render_error(@student_quiz.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  # Delete a student quiz
  def destroy
    @student_quiz.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error('Record does not exist', :not_found)
  end

  private

  # Set the student quiz based on the ID provided in the route
  def set_student_quiz
    @student_quiz = find_resource_by_id(Questionnaire, params[:id])
  end

  # Find the response map for the current user's attempt to submit quiz answers
  def find_response_map_for_current_user
    ResponseMap.find_by(
      reviewee_id: current_user.id,
      reviewed_object_id: params[:questionnaire_id]
    )
  end

  # Process and calculate the total score for submitted answers
  def process_answers(answers, response_map)
    answers.sum do |answer|
      question = Question.find(answer[:question_id])
      submitted_answer = answer[:answer_value]

      response = find_or_initialize_response(response_map.id, question.id)
      response.submitted_answer = submitted_answer
      response.save!

      question.correct_answer == submitted_answer ? question.score_value : 0
    end
  end

  # Find or initialize a response for a specific question within an attempt
  def find_or_initialize_response(response_map_id, question_id)
    Response.find_or_initialize_by(
      response_map_id: response_map_id,
      question_id: question_id
    )
  end

  # Find a specific resource by ID, handling the case where it's not found
  def find_resource_by_id(model, id)
    model.find(id)
  rescue ActiveRecord::RecordNotFound
    render_error("#{model.name} not found", :not_found)
    nil
  end

  # Check if a quiz has already been assigned to a participant
  def quiz_already_assigned?(participant, questionnaire)
    ResponseMap.exists?(
      reviewee_id: participant.user_id,
      reviewed_object_id: questionnaire.id
    )
  end

  # Build a new ResponseMap instance for assigning a quiz to a student
  def build_response_map(student_id, questionnaire)
    instructor_id = questionnaire.assignment.instructor_id
    ResponseMap.new(
      reviewee_id: student_id,
      reviewer_id: instructor_id,
      reviewed_object_id: questionnaire.id
    )
  end

  # Create a new questionnaire along with its questions and answers
  def create_questionnaire(params)
    Questionnaire.create!(params)
  end

  # Create questions and their respective answers for a questionnaire
  def create_questions_and_answers(questionnaire, questions_attributes)
    questions_attributes.each do |question_attr|
      question = questionnaire.questions.create!(question_attr.except(:answers_attributes))
      question_attr[:answers_attributes]&.each do |answer_attr|
        question.answers.create!(answer_attr)
      end
    end
  end

  # Permit and require the necessary parameters for creating/updating a questionnaire
  def questionnaire_params
    params.require(:questionnaire).permit(
      :name, :instructor_id, :min_question_score, :max_question_score, :assignment_id,
      questions_attributes: [:id, :txt, :question_type, :break_before, :correct_answer, :score_value,
                             { answers_attributes: %i[id answer_text correct] }]
    )
  end

  # Render a success response with optional custom status code
  def render_success(data, status = :ok)
    render json: data, status: status
  end

  # Render an error response with message and status code
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end

  # Ensure only instructors can perform certain actions
  def check_instructor_role
    unless current_user.role_id == 3 # Assuming 3 is the role ID for instructors
      render_error('Only instructors are allowed to perform this action', :forbidden)
    end
  end
end