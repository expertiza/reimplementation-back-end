class Api::V1::QuestionsController < ApplicationController
  before_action :set_question, only: [:show, :update]

  # GET /questions
  def action_allowed?
    has_role?('Instructor')
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

  # GET /api/v1/questions/show_all/questionnaire/:id
  def show_all
    questionnaire = Questionnaire.find(params[:id])
    items = questionnaire.items.order(:id)
    render json: items, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Questionnaire" }, status: :not_found
  end

  # POST /questions
  def create
    questionnaire_id = params[:questionnaire_id]
    questionnaire = Questionnaire.find(questionnaire_id)

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
    end

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

  # DELETE /api/v1/questions/delete_all/questionnaire/:id
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


  private

  def set_question
    @item = Item.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:txt, :question_type, :seq, :weight, :max_value, :size, :alternatives)
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
