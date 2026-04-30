class QuestionsController < ApplicationController
  before_action :set_question, only: [:show, :update]

  # GET /questions
  def action_allowed?
    current_user_has_role?('Instructor')
  end
  # Index method returns the list of questions JSON object
  # GET on /questions
  def index
    @questions = Item.order(:id)
    render json: @questions, status: :ok
  end

  # GET /questions/:id
  def show
    begin
      @item = Item.find(params[:id])

      # Choose the correct strategy based on item type
      strategy = get_strategy_for_item(@item)

      # Render the item using the strategy
      @rendered_item = strategy.render(@item)

      render json: { item: @item, rendered_item: @rendered_item }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Question not found" }, status: :not_found
    end
  end

  # GET /questions/show_all/questionnaire/:id
  def show_all
    questionnaire = Questionnaire.find(params[:id])
    items = questionnaire.items.order(:id)
    render json: items, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Questionnaire" }, status: :not_found
  end

  # Item types that are valid inside a Quiz questionnaire.
  # These types either store the student's answer in the +comments+ column
  # (TextField, MultipleChoiceRadio, MultipleChoiceCheckbox) or via a numeric
  # answer (Scale, Checkbox). Only items of these types may carry a
  # +correct_answer+ value and be auto-scored at submission time.
  QUIZ_ITEM_TYPES = %w[TextField MultipleChoiceRadio MultipleChoiceCheckbox Scale Checkbox].freeze

  # Creates a new {Item} under the given questionnaire.
  #
  # For quiz questionnaires the item type is validated against {QUIZ_ITEM_TYPES}
  # and the optional +correct_answer+ parameter is persisted so the backend can
  # score the student's response at submission time.
  #
  # Type-specific defaults (size, labels, alternatives) are set automatically
  # so callers only need to supply the data that varies per item.
  #
  # @param questionnaire_id [Integer] ID of the parent questionnaire (URL segment)
  # @param question_type [String] one of the supported item type strings
  # @param txt [String] the item's prompt text
  # @param seq [Integer] display order within the questionnaire
  # @param weight [Integer] point value used during scoring
  # @param correct_answer [String, nil] expected answer; only used for quiz items
  # @return [201] the created {Item} as JSON
  # @return [422] validation errors or unsupported quiz item type
  # POST /questions
  def create
    questionnaire_id = params[:questionnaire_id]
    questionnaire = Questionnaire.find(questionnaire_id)
    is_quiz = %w[Quiz QuizQuestionnaire].include?(questionnaire.questionnaire_type)

    # For quiz questionnaires, only allow the supported quiz item types
    if is_quiz && !QUIZ_ITEM_TYPES.include?(params[:question_type])
      return render json: { error: "Invalid quiz item type. Allowed types: #{QUIZ_ITEM_TYPES.join(', ')}" },
                    status: :unprocessable_entity
    end

    # Create the new Item (item)
    item = questionnaire.items.build(
      txt: params[:txt],
      question_type: params[:question_type],
      seq: params[:seq],
      break_before: true
    )

    # Add attributes based on the item type
    case item.question_type
    when 'Scale'
      item.weight = params[:weight]
      item.max_label = 'Strongly agree'
      item.min_label = 'Strongly disagree'
      item.max_value = params[:max_value] || 5
    when 'Dropdown'
      item.alternatives = '0|1|2|3|4|5'
    when 'TextArea'
      item.size = '60, 5'
    when 'TextField'
      item.size = '30'
    when 'Checkbox'
      item.break_before = true
    end

    # For quiz items, store the correct_answer
    item.correct_answer = params[:correct_answer] if is_quiz

    if item.save
      render json: item, status: :created
    else
      render json: { error: item.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PUT /questions/:id
  def update
    if @item.update(question_params)
      render json: @item, status: :ok
    else
      render json: { error: @item.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    @item = Item.find(params[:id])
    @item.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Item" }, status: :not_found
  end

  # DELETE /questions/delete_all/questionnaire/:id
  def delete_all
    questionnaire = Questionnaire.find(params[:id])
    if questionnaire.items.delete_all
      render json: { message: "All questions deleted" }, status: :ok
    else
      render json: { error: "Deletion failed" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Questionnaire" }, status: :not_found
  end

  def types
    types = Item.pluck(:question_type).uniq
    render json: types, status: :ok
  end

  # Returns the list of item type strings that are permitted inside a quiz
  # questionnaire. Consumed by the frontend questionnaire editor to populate
  # the item-type selector when the questionnaire type is "Quiz".
  #
  # @return [200] JSON array of allowed quiz item type strings (see {QUIZ_ITEM_TYPES})
  # GET /questions/quiz_types
  def quiz_types
    render json: QUIZ_ITEM_TYPES, status: :ok
  end


  private

  def set_question
    @item = Item.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:txt, :question_type, :seq, :weight, :max_value, :size, :alternatives,
                                     :correct_answer)
  end

  def get_strategy_for_item(item)
    case item.question_type
    when 'Dropdown'
      Strategies::DropdownStrategy.new
    when 'Scale'
      Strategies::ScaleStrategy.new
    # You can add more strategies as needed
    else
      raise "Strategy for this item type not defined"
    end
  end
end
