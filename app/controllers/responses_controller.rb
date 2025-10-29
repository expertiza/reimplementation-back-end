# frozen_string_literal: true

class ResponsesController < ApplicationController
  before_action :set_response, only: [:update, :submit, :unsubmit, :destroy]

  # Authorization: determines if current user can perform the action
  def action_allowed?
    case action_name
    when 'create'
      true
    when 'update', 'submit'
      @response = Response.find(params[:id])
      # user_id = response.map.reviewer.user_id if response.map.reviewer
      unless owns_response_or_map? || has_role?('Instructor') || has_role?('Admin')
        # puts "current_user.id: #{current_user.id}, user_id: #{user_id}"
        render json: { error: 'forbidden' }, status: :forbidden
      end
    when 'unsubmit', 'destroy'
      unless has_role?('Instructor') || has_role?('Admin')
        render json: { error: 'forbidden' }, status: :forbidden
      end
    else
      render json: { error: 'forbidden' }, status: :forbidden
    end
    true
  end

  # POST /responses
  def create
    @response_map = ResponseMap.find_by(id: params[:response_map_id] || params[:map_id])
    return render json: { error: 'ResponseMap not found' }, status: :not_found unless @response_map

    @response = Response.new(
      map_id: @response_map.id,
      is_submitted: false,
      created_at: Time.current
    )

    if @response.save
      render json: { message: 'Response draft created successfully', response: @response }, status: :created
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id
  # Reviewer edits existing draft (still unsubmitted)
  def update
    puts "Updating Response ID: #{params[:id]}"
    return render json: { error: 'forbidden' }, status: :forbidden if @response.is_submitted?

    if @response.update(response_params)
      render json: { message: 'Draft updated successfully', response: @response }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/submit
  # Lock the response and calculate final score
  def submit
    return render json: { error: 'Response not found' }, status: :not_found unless @response
    return render json: { error: 'Response already submitted' }, status: :unprocessable_entity if @response.is_submitted?

    # Check deadline
    return render json: { error: 'Deadline has passed' }, status: :forbidden unless deadline_open?(@response)

    # Validate rubric completion
    unanswered = @response.scores.select { |a| a.answer.nil? }
    return render json: { error: 'All rubric items must be answered' }, status: :unprocessable_entity unless unanswered.empty?

    # Lock response
    @response.is_submitted = true

    # Calculate score via ScorableHelper
    total_score = @response.aggregate_questionnaire_score

    if @response.save
      render json: {
        message: 'Response submitted successfully',
        response: @response,
        total_score: total_score
      }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/unsubmit
  # Instructor/Admin reopens a submitted response
  def unsubmit
    return render json: { error: 'Response not found' }, status: :not_found unless @response

    if @response.is_submitted?
      @response.update(is_submitted: false)
      render json: { message: 'Response reopened for revision', response: @response }, status: :ok
    else
      render json: { error: 'Response already unsubmitted' }, status: :unprocessable_entity
    end
  end

  # DELETE /responses/:id
  # Instructor/Admin deletes invalid/test response
  def destroy
    return render json: { error: 'Response not found' }, status: :not_found unless @response

    @response.destroy
    head :no_content
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_response
    @response = Response.find_by(id: params[:id])
  end

  def response_params
    params.require(:response).permit(
      :map_id,
      :is_submitted,
      :submitted_at,
      scores_attributes: [:id, :question_id, :answer, :comment]
    )
  end

  def owns_response_or_map?
    # Member actions: we have @response from set_response
    puts "Checking ownership for Response ID: #{@response&.id}"
    puts "ResponseMap associated: #{@response&.map&.reviewer&.id}"
    puts "Current User ID: #{current_user&.id}"
    return @response.map&.reviewer&.id == current_user.id if @response&.map&.reviewer && current_user

    # Collection actions (create, next_action): check map ownership
    puts "Checking ownership for ResponseMap ID from params"
    map_id = params[:response_map_id] || params[:map_id]
    return false if map_id.blank?

    map = ResponseMap.find_by(id: map_id)
    puts "Found ResponseMap: #{map.inspect}"
    return false unless map

    puts "Checking ownership: map.reviewer_id=#{map.reviewer_id}, current_user.id=#{current_user.id}"
    map.reviewer == current_user
  end

  # Returns true if the assignment's due date is in the future or no due date is set
  def deadline_open?(response)
    assignment = response.respond_to?(:response_map) ? response.response_map&.assignment : nil
    return true if assignment.nil?
    return true if assignment.respond_to?(:due_dates) && assignment.due_dates.nil?
    # if due_date responds to future? use it, otherwise compare to now
    if assignment.respond_to?(:due_dates) && assignment.due_dates.respond_to?(:future?)
      return assignment.due_dates.first.future?
    end
    # fallback: compare
    due = assignment.due_dates
    return true if due.nil?
    puts "Checking deadline: due_at=#{due.inspect}, current_time=#{Time.current}"
    due.first.due_at > Time.current
  end
end
