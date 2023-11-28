class Api::V1::QuizQuestionnairesController < ApplicationController

  # Action to retrieve a list of quiz questionnaires
  def index
    @quiz_questionnaires = Questionnaire.where(questionnaire_type: 'Quiz Questionnaire').order(:id)
    render json: @quiz_questionnaires, status: :ok and return
  end

  # Action to retrieve details of a single quiz questionnaire
  def show
    begin
      @questionnaire = Questionnaire.find(params[:id])
      render json: @questionnaire, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      # Handle the case when the questionnaire is not found
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # Action to create a new quiz questionnaire
  def create
    begin

      @assignment_id = params[:assignment_id] # creating an instance variable to hold the assignment id
      @participant_id = params[:participant_id] # creating an instance variable to hold the participant id
      @team_id = params[:team_id] # creating an instance variable to hold the team id
      @user_id = params[:user_id] # creating an instance variable to hold the user id

      if check_privilege(@user_id) == false
        err = 'You do not have the required permission'
        render json: err, status: :unprocessable_entity and return
      end

      assignment = Assignment.find(@assignment_id)

      if assignment.require_quiz?
        valid_request = team_valid?(@team_id, @participant_id) # check for validity of the request
      else
        err = 'This assignment is not configured to use quizzes.'
        render json: err, status: :unprocessable_entity and return
        valid_request = false
      end

      if valid_request && check_questionnaire_type(params[:questionnaire_type])
        # Create a new QuizQuestionnaire instance and set its attributes
        @questionnaire = QuizQuestionnaire.new(questionnaire_params)
        @questionnaire.instructor_id = @team_id
        @questionnaire.display_type = params[:questionnaire_type].split('Questionnaire')[0]
        @questionnaire.assignment_id = @assignment_id
        # render json: @questionnaire, status: :ok and return

        if @questionnaire.min_question_score < 0 || @questionnaire.max_question_score < 0
          err = 'Minimum and/or maximum question score cannot be less than 0.'
          render json: err, status: :unprocessable_entity and return
        elsif @questionnaire.max_question_score < @questionnaire.min_question_score
          err = 'Maximum question score cannot be less than minimum question score.'
          render json: err, status: :unprocessable_entity and return
        else
          @questionnaire.save
          render json: @questionnaire, status: :created and return
        end

      else
        err = 'Validation Errors.'
        render json: err, status: :unprocessable_entity and return
      end

    end
  end

  # Action to update an existing quiz questionnaire
  def update

    @user_id = params[:user_id]
    if check_privilege(@user_id) == false
      err = 'You do not have the required permission'
      render json: err, status: :unprocessable_entity and return
    end

    @questionnaire = Questionnaire.find(params[:id])
    if @questionnaire.update(questionnaire_params)
      render json: @questionnaire, status: :ok and return
    else
      render json: @questionnaire.errors.full_messages, status: :unprocessable_entity and return
    end
  end

  # Action to delete a quiz questionnaire
  def destroy
    begin

      @user_id = params[:user_id] # creating an instance variable to hold the user id

      if check_privilege(@user_id) == false
        err = 'You do not have the required permission'
        render json: err, status: :unprocessable_entity and return
      end

      @questionnaire = Questionnaire.find(params[:id])
      @questionnaire.delete
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # Action to create a copy of a quiz questionnaire
  def copy
    begin
      @questionnaire = Questionnaire.copy_questionnaire_details(params)
      render json: @questionnaire, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    rescue ActiveRecord::RecordInvalid
      render json: $ERROR_INFO.to_s, status: :unprocessable_entity
    end
  end


  private

  # Check user's privilege based on their role
  def check_privilege(user_id)
    role_id = User.find(user_id).role_id
    role = Role.find(role_id).name

    role.eql?('Student') or role.eql?('Administrator') or role.eql?('Super Administrator')
  end

  # Check if the team is valid for the given participant
  def team_valid?(team_id, participant_id)
    participantTeamID = Participant.find(participant_id).team_id
    team_id.eql?(participantTeamID)
  end

  # Define the permitted parameters for creating/updating a questionnaire
  def questionnaire_params
    params.require(:quiz_questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id, :assignment_id)
  end

  # Check if the questionnaire type is "Quiz Questionnaire"
  def check_questionnaire_type(type)
    type.eql?("Quiz Questionnaire")
  end

end

