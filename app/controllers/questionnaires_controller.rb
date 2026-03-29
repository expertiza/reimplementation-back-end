class QuestionnairesController < ApplicationController
  
  # Index method returns the list of JSON objects of the questionnaire
  # GET on /questionnaires
  def index
    @questionnaires = Questionnaire.order(:id)
    render json: @questionnaires, status: :ok and return
  end
  
  # Show method returns the JSON object of questionnaire with id = {:id}
  # GET on /questionnaires/:id
  # Includes nested +items+ (rubric lines) so the SPA can edit without a separate GET .../items route.
  def show
    @questionnaire = Questionnaire.includes(:items).find(params[:id])
    render json: questionnaire_show_json(@questionnaire), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: $ERROR_INFO.to_s, status: :not_found
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
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
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

  # Builds the show payload: same fields as Questionnaire#as_json plus ordered items for the editor.
  def questionnaire_show_json(questionnaire)
    questionnaire.as_json.tap do |data|
      data['items'] = questionnaire.items.order(:seq).map { |item| item_json_for_api(item) }
    end
  end

  def item_json_for_api(item)
    item.attributes.slice(
      'id', 'questionnaire_id', 'txt', 'weight', 'seq', 'question_type', 'size', 'alternatives',
      'break_before', 'min_label', 'max_label', 'created_at', 'updated_at'
    )
  end

  def questionnaire_params
    params.require(:questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id,
                                          items_attributes: %i[id txt weight seq question_type size alternatives break_before min_label max_label _destroy])
  end

  def sanitize_display_type(type)
    display_type = type.split('Questionnaire')[0]
    display_type = 'Review' if display_type == 'Review rubric'
    if %w[AuthorFeedback CourseSurvey TeammateReview GlobalSurvey AssignmentSurvey BookmarkRating].include?(display_type)
      display_type = (display_type.split(/(?=[A-Z])/)).join('%')
    end
    display_type
  end

end