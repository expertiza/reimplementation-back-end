class QuestionnairesController < ApplicationController
  DISPLAY_TYPES = [
    'Review',
    'Metareview',
    'Author feedback',
    'Teammate Review',
    'Survey',
    'Assignment survey',
    'Global survey',
    'Course survey',
    'Bookmark rating',
    'Quiz'
  ].freeze

  TYPE_DISPLAY_MAP = {
    'ReviewQuestionnaire' => 'Review',
    'MetareviewQuestionnaire' => 'Metareview',
    'Author FeedbackQuestionnaire' => 'Author feedback',
    'AuthorFeedbackQuestionnaire' => 'Author feedback',
    'Teammate ReviewQuestionnaire' => 'Teammate Review',
    'TeammateReviewQuestionnaire' => 'Teammate Review',
    'SurveyQuestionnaire' => 'Survey',
    'AssignmentSurveyQuestionnaire' => 'Assignment survey',
    'Assignment SurveyQuestionnaire' => 'Assignment survey',
    'Global SurveyQuestionnaire' => 'Global survey',
    'GlobalSurveyQuestionnaire' => 'Global survey',
    'Course SurveyQuestionnaire' => 'Course survey',
    'CourseSurveyQuestionnaire' => 'Course survey',
    'Bookmark RatingQuestionnaire' => 'Bookmark rating',
    'BookmarkRatingQuestionnaire' => 'Bookmark rating',
    'QuizQuestionnaire' => 'Quiz'
  }.freeze
  
  # Index method returns the list of JSON objects of the questionnaire
  # GET on /questionnaires
  def index
    @questionnaires = Questionnaire.order(:id)
    render json: @questionnaires, status: :ok and return
  end

  # Hierarchical list of questionnaire types and questionnaires available to the current user.
  # GET on /questionnaires/hierarchical
  def hierarchical
    questionnaires = Questionnaire
                     .includes(:instructor)
                     .where(private: false)
                     .or(Questionnaire.where(instructor_id: current_user.id))
                     .order(:name)
                     .distinct

    grouped_questionnaires = questionnaires.group_by do |questionnaire|
      display_type_for(questionnaire.questionnaire_type)
    end

    render json: DISPLAY_TYPES.map { |display_type|
      {
        type: display_type,
        questionnaires: (grouped_questionnaires[display_type] || []).map(&:as_json)
      }
    }, status: :ok and return
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

  # GET /questionnaires/:id/items
  def items
    questionnaire = Questionnaire.find(params[:id])
    render json: questionnaire.items.order(:seq), status: :ok and return
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Questionnaire not found" }, status: :not_found and return
  end
  
  # Create method creates a questionnaire and returns the JSON object of the created questionnaire
  # POST on /questionnaires
  # Instructor Id statically defined since implementation of Instructor model is out of scope of E2345.
  def create
    begin
      questionnaire_attributes, item_attributes = split_questionnaire_params
      @questionnaire = Questionnaire.new(questionnaire_attributes)
      @questionnaire.display_type = sanitize_display_type(@questionnaire.questionnaire_type)
      Questionnaire.transaction do
        @questionnaire.save!
        sync_items!(@questionnaire, item_attributes)
      end
      render json: @questionnaire, status: :created and return
    rescue ActiveRecord::RecordInvalid
      render json: { errors: $ERROR_INFO.record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Destroy method deletes the questionnaire object with id- {:id}
  # DELETE on /questionnaires/:id
  def destroy
    begin
      @questionnaire = Questionnaire.find(params[:id])
      @questionnaire.destroy!
      render json: { message: 'Questionnaire deleted successfully' }, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
      render json: { error: $ERROR_INFO.message }, status: :unprocessable_entity and return
    end
  end

  # Update method updates the questionnaire object with id - {:id} and returns the updated questionnaire JSON object
  # PUT on /questionnaires/:id

  def update
    @questionnaire = Questionnaire.find(params[:id])
    questionnaire_attributes, item_attributes = split_questionnaire_params

    Questionnaire.transaction do
      @questionnaire.update!(questionnaire_attributes)
      sync_items!(@questionnaire, item_attributes)
    end

    render json: @questionnaire, status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { errors: $ERROR_INFO.record.errors.full_messages }, status: :unprocessable_entity
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
    params.require(:questionnaire).permit(
      :name,
      :questionnaire_type,
      :private,
      :min_question_score,
      :max_question_score,
      :instructor_id,
      items_attributes: [
        :id,
        :txt,
        :question_type,
        :weight,
        :alternatives,
        :min_label,
        :max_label,
        :seq,
        :break_before,
        :textarea_width,
        :textarea_height,
        :textbox_width,
        :row_names,
        :col_names,
        :_destroy
      ]
    )
  end

  def sanitize_display_type(type)
    display_type = type.split('Questionnaire')[0]
    if %w[AuthorFeedback CourseSurvey TeammateReview GlobalSurvey AssignmentSurvey BookmarkRating].include?(display_type)
      display_type = (display_type.split(/(?=[A-Z])/)).join('%')
    end
    display_type
  end

  def display_type_for(questionnaire_type)
    TYPE_DISPLAY_MAP.fetch(questionnaire_type, questionnaire_type.to_s.delete_suffix('Questionnaire'))
  end

  def split_questionnaire_params
    permitted_params = questionnaire_params.to_h.deep_symbolize_keys
    items_attributes = permitted_params.delete(:items_attributes) || []
    [permitted_params, items_attributes]
  end

  def sync_items!(questionnaire, item_attributes)
    item_attributes.each_with_index do |item_data, index|
      destroy_item = ActiveModel::Type::Boolean.new.cast(item_data[:_destroy])

      if destroy_item && item_data[:id].present?
        questionnaire.items.find(item_data[:id]).destroy!
        next
      end

      next if destroy_item

      if item_data[:id].present?
        existing_item = questionnaire.items.find(item_data[:id])
        attributes = build_item_attributes(item_data, index, existing_item)
        existing_item.update!(attributes)
      else
        attributes = build_item_attributes(item_data, index)
        questionnaire.items.create!(attributes)
      end
    end
  end

  def build_item_attributes(item_data, index, existing_item = nil)
    question_type = canonical_question_type(item_data[:question_type])
    {
      txt: item_data[:txt].presence || existing_item&.txt,
      question_type: question_type,
      weight: item_data[:weight].presence || existing_item&.weight,
      seq: item_data[:seq].presence || index + 1,
      alternatives: normalize_alternatives(item_data[:alternatives]) || existing_item&.alternatives,
      min_label: item_data[:min_label].presence || existing_item&.min_label,
      max_label: item_data[:max_label].presence || existing_item&.max_label,
      break_before: item_data.key?(:break_before) ? ActiveModel::Type::Boolean.new.cast(item_data[:break_before]) : true,
      size: build_item_size(question_type, item_data, existing_item)
    }.compact
  end

  def canonical_question_type(question_type)
    {
      'Text area' => 'TextArea',
      'Text field' => 'TextField',
      'Multiple choice' => 'MultipleChoiceRadio'
    }.fetch(question_type, question_type)
  end

  def normalize_alternatives(alternatives)
    return nil if alternatives.blank?

    alternatives.to_s.split(',').map(&:strip).reject(&:empty?).join('|')
  end

  def build_item_size(question_type, item_data, existing_item = nil)
    case question_type
    when 'Criterion', 'TextArea'
      width = item_data[:textarea_width].presence
      height = item_data[:textarea_height].presence
      return "#{width},#{height}" if width && height
    when 'TextField'
      return item_data[:textbox_width].to_s if item_data[:textbox_width].present?
    end

    existing_item&.size
  end

end
