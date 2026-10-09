class ItemsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :set_item, only: %i[show update]

  # GET /items (instructors only)
  def action_allowed?
    current_user_has_role?('Instructor')
  end

  # Index method returns the list of items as a JSON object
  # GET /items
  def index
    @items = Item.order(:id)
    render json: @items, status: :ok
  end

  # GET /items/:id
  def show
    @item = Item.find(params[:id])

    # Choose the correct strategy based on item type
    strategy = get_strategy_for_item(@item)

    # Render the item using the strategy
    @rendered_item = strategy.render(@item)

    render json: { item: @item, rendered_item: @rendered_item }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Item not found' }, status: :not_found
  end

  # GET /items/show_all/questionnaire/:id
  def show_all
    questionnaire = Questionnaire.find(params[:id])
    items = questionnaire.items.order(:id)
    render json: items, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Questionnaire" }, status: :not_found
  end

  # POST /items
  def create
    questionnaire_id = params[:questionnaire_id]
    questionnaire = Questionnaire.find(questionnaire_id)

    # Build the new Item using the frontend-facing param names
    item = questionnaire.items.build(
      txt: params[:prompt], # prompt maps to the txt DB column
      question_type: params[:question_type],
      seq: params[:seq],
      break_before: true
    )

    apply_type_defaults(item)

    if item.save
      render json: item, status: :created
    else
      render json: { error: item.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PUT /items/:id
  def update
    if @item.update(item_params)
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

  # DELETE /items/delete_all/questionnaire/:id
  def delete_all
    questionnaire = Questionnaire.find(params[:id])
    if questionnaire.items.delete_all
      render json: { message: 'All questions deleted' }, status: :ok
    else
      render json: { error: 'Deletion failed' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Couldn't find Questionnaire" }, status: :not_found
  end

  def types
    render json: Item::QUESTION_TYPES, status: :ok
  end

  private

  # Set size and alternatives from structured params
  def apply_type_defaults(item)
    case item.question_type
    when 'Scale'
      item.weight = params[:weight]
      item.max_label = 'Strongly agree'
      item.min_label = 'Strongly disagree'
    when 'Dropdown'
      item.alternatives = '0|1|2|3|4|5'
    else
      apply_size(item)
    end
  end

  def apply_size(item)
    case item.question_type
    when 'TextArea'
      # rows and columns stored as "columns,rows" in the size field
      item.size = "#{params[:columns] || 60},#{params[:rows] || 5}"
    when 'TextField'
      item.size = (params[:columns] || 30).to_s
    end
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    # The frontend sends :prompt, which maps to the txt column.
    permitted = params.require(:item).permit(:prompt, :txt, :question_type, :seq, :weight, :alternatives,
                                             :size, :break_before, :min_label, :max_label)
    prompt = permitted.delete(:prompt)
    permitted[:txt] = prompt if prompt
    permitted
  end

  def get_strategy_for_item(item)
    case item.question_type
    when 'Dropdown'
      Strategies::DropdownStrategy.new
    when 'Scale'
      Strategies::ScaleStrategy.new
    # You can add more strategies as needed
    else
      raise 'Strategy for this item type not defined'
    end
  end
end
