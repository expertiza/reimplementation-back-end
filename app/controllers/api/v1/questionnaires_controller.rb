class Api::V1::QuestionnairesController < ApplicationController
  
  # Index method returns the list of JSON objects of the questionnaire
  # GET on /questionnaires
  def index
    @questionnaires = Questionnaire.order(:id)
    render json: @questionnaires, status: :ok and return
  end
  
  # Show method returns the JSON object of questionnaire with id = {:id}
  # GET on /questionnaires/:id
  def show
    begin
      @questionnaire = Questionnaire.find(params[:id])
      render json: @questionnaire, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end
  
  # Create method creates a questionnaire and returns the JSON object of the created questionnaire
  # POST on /questionnaires
  # Instructor Id statically defined since implementation of Instructor model is out of scope of E2345.
  def create
    begin
      @questionnaire = Questionnaire.new(questionnaire_params)
      @questionnaire.display_type = sanitize_display_type(@questionnaire.questionnaire_type)
      @questionnaire.save!
      render json: @questionnaire, status: :created and return
    rescue ActiveRecord::RecordInvalid
      render json: $ERROR_INFO.to_s, status: :unprocessable_entity
    end
  end

  # Destroy method deletes the questionnaire object with id- {:id}
  # DELETE on /questionnaires/:id
  def destroy
    begin
      @questionnaire = Questionnaire.find(params[:id])
      @questionnaire.delete
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # Update method updates the questionnaire object with id - {:id} and returns the updated questionnaire JSON object
  # PUT on /questionnaires/:id

  def update
    @questionnaire = Questionnaire.find(params[:id])
    if @questionnaire.update(questionnaire_params)
      render json: @questionnaire, status: :ok
    else
      render json: @questionnaire.errors.full_messages, status: :unprocessable_entity
    end
  end
  # Copy method creates a copy of questionnaire with id - {:id} and return its JSON object
  # POST on /questionnaires/copy/:id
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

  # Toggle access method toggles the private variable of the questionnaire with id - {:id} and return its JSON object
  # GET on /questionnaires/toggle_access/:id

  def toggle_access
    begin
      @questionnaire = Questionnaire.find(params[:id])
      @questionnaire.toggle!(:private)
      @access = @questionnaire.private ? 'private' : 'public'
      render json: "The questionnaire \"#{@questionnaire.name}\" has been successfully made #{@access}. ",
        status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found
    rescue ActiveRecord::RecordInvalid
      render json: $ERROR_INFO.to_s, status: :unprocessable_entity
    end
  end

  private

  def questionnaire_params
    params.require(:questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id)
  end

  def sanitize_display_type(type)
    display_type = type.split('Questionnaire')[0]
    if %w[AuthorFeedback CourseSurvey TeammateReview GlobalSurvey AssignmentSurvey BookmarkRating].include?(display_type)
      display_type = (display_type.split(/(?=[A-Z])/)).join('%')
    end
    display_type
  end

end