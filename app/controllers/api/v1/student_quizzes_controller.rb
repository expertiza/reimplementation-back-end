class Api::V1::StudentQuizzesController < ApplicationController
  before_action :check_instructor_role, except: [:submit_answers]
  before_action :set_student_quiz, only: [:show, :update, :destroy]

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render_error(exception.message)
  end

  #GET /student_quizzes
  def index
    quizzes = Questionnaire.all
    render_success(quizzes)
  end

  #GET /student_quizzes/:id
  def show
    render_success(@student_quiz)
  end

  #POST /student_quizzes
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

  #POST /student_quizzes/assign
  def assign_quiz
    participant = FindResourceService.call(Participant, params[:participant_id])
    questionnaire = FindResourceService.call(Questionnaire, params[:questionnaire_id])
    return unless participant && questionnaire

    if quiz_assigned?(participant, questionnaire)
      render_error("This student is already assigned to the quiz.", :unprocessable_entity)
      return
    end

    response_map = build_response_map(participant.user_id, questionnaire)
    if response_map.save
      render_success(response_map, :created)
    else
      render_error(response_map.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  #POST /student_quizzes/submit_answers
  def submit_quiz
    ActiveRecord::Base.transaction do
      response_map = ResponseMap.find_for_current_user(current_user, params[:questionnaire_id])
      unless response_map
        render_error("You are not assigned to take this quiz.", :forbidden)
        return
      end

      response_map.process_answers(params[:answers])
      total_score = response_map.calculate_score
      response_map.update!(score: total_score)
      render_success({ total_score: total_score })
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.message, :unprocessable_entity)
  end

  #PUT /student_quizzes/:id
  def update
    if @student_quiz.update(questionnaire_params)
      render_success(@student_quiz)
    else
      render_error(@student_quiz.errors.full_messages.to_sentence, :unprocessable_entity)
    end
  end

  #DELETE /student_quizzes/:id
  def destroy
    @student_quiz.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render_error('Record does not exist', :not_found)
  end

  private

  #To get quiz from db
  def fetch_quiz
    @student_quiz = FindResourceService.call(Questionnaire, params[:id])
  end
  
  # Check if a quiz has already been assigned to a participant
  def quiz_assigned?(participant, questionnaire)
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
    unless current_user.role_id == 2
      render_error('Only instructors are allowed to perform this action', :forbidden)
    end
  end
end
