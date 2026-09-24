class QuestionnairesController < ApplicationController

  # Index method returns the list of JSON objects of the questionnaire.
  # Supports an optional ?type= query parameter to filter by questionnaire_type.
  # GET on /questionnaires
  # GET on /questionnaires?type=ReviewQuestionnaire
  def index
    if params[:type].present?
      unless Questionnaire::QUESTIONNAIRE_TYPES.include?(params[:type])
        render json: "Invalid questionnaire type: #{params[:type]}", status: :unprocessable_entity and return
      end

      @questionnaires = Questionnaire.by_type(params[:type]).order(:id)
    else
      @questionnaires = Questionnaire.order(:id)
    end
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
  
  # Create method creates a questionnaire and returns the JSON object of the created questionnaire.
  # Instantiates the correct subclass (e.g. ReviewQuestionnaire) so that subclass callbacks
  # such as after_initialize run and set display_type correctly.
  # POST on /questionnaires
  def create
    begin
      type = params.dig(:questionnaire, :questionnaire_type)
      unless Questionnaire::QUESTIONNAIRE_TYPES.include?(type)
        render json: "Invalid questionnaire type: #{type}", status: :unprocessable_entity and return
      end

      klass = type.constantize
      @questionnaire = klass.new(questionnaire_params)
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
      @questionnaire = Questionnaire.copy(params)
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
    params.require(:questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id, items_attributes: [:id, :txt, :question_type, :weight, :seq, :min_label, :max_label, :alternatives, :size, :break_before, :_destroy])
  end

  def sanitize_display_type(type)
    display_type = type.split('Questionnaire')[0]
    if %w[AuthorFeedback CourseSurvey TeammateReview GlobalSurvey AssignmentSurvey BookmarkRating].include?(display_type)
      display_type = (display_type.split(/(?=[A-Z])/)).join('%')
    end
    display_type
  end

end