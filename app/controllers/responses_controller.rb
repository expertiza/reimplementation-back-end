# frozen_string_literal: true

class ResponsesController < ApplicationController
  before_action :set_response, only: %i[update save_draft submit unsubmit destroy]
  # before_action :authorize_action

  # Authorization: determines if current user can perform the action
  def action_allowed?
    case action_name
    when 'create', 'update', 'save_draft', 'submit'
      render json: { error: 'forbidden' }, status: :forbidden unless has_role?('Reviewer') && owns_response_or_map?
    when 'unsubmit', 'destroy'
      render json: { error: 'forbidden' }, status: :forbidden unless has_role?('Instructor') || has_role?('Admin')
    end
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
    return render json: { error: 'forbidden' }, status: :forbidden if @response.is_submitted?
    return render json: { error: 'Deadline has passed' }, status: :forbidden unless deadline_open?(@response)

    if @response.update(response_params)
      render json: { message: 'Draft updated successfully', response: @response }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/save_draft
  # Reviewer saves progress without submitting
  def save_draft
    return render json: { error: 'forbidden' }, status: :forbidden unless has_role?('Reviewer') # or rely on guard
    return render json: { error: 'Deadline has passed' }, status: :forbidden unless deadline_open?(@response)

    if @response.is_submitted?
      return render json: { error: 'Response already submitted' },
                    status: :unprocessable_entity
    end

    if @response.update(response_params)
      render json: { message: 'Draft saved successfully', response: @response }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/submit
  # Lock the response and calculate final score
  def submit
    return render json: { error: 'Response not found' }, status: :not_found unless @response

    if @response.is_submitted?
      return render json: { error: 'Response already submitted' },
                    status: :unprocessable_entity
    end

    # Check deadline
    return render json: { error: 'Deadline has passed' }, status: :forbidden unless deadline_open?(@response)

    # Validate rubric completion
    unanswered = @response.scores.select { |a| a.answer.nil? }
    unless unanswered.empty?
      return render json: { error: 'All rubric items must be answered' },
                    status: :unprocessable_entity
    end

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

  # Returns true if the assignment's due date is in the future or no due date is set
  def deadline_open?(response)
    assignment = response.respond_to?(:response_map) ? response.response_map&.assignment : nil
    return true if assignment.nil?
    return true if assignment.respond_to?(:due_date) && assignment.due_date.nil?
    # if due_date responds to future? use it, otherwise compare to now
    return assignment.due_date.future? if assignment.respond_to?(:due_date) && assignment.due_date.respond_to?(:future?)

    # fallback: compare
    due = assignment.due_date
    return true if due.nil?

    due > Time.current
  end

  # PATCH /responses/:id/unsubmit
  # Instructor/Admin reopens a submitted response
  def unsubmit
    return render json: { error: 'Response not found' }, status: :not_found unless @response

    if @response.is_submitted?
      @response.update(is_submitted: false, submitted_at: nil)
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
    render json: { error: 'Response not found' }, status: :not_found and return unless @response
  end

  def response_params
    params.require(:response).permit(
      :map_id,
      :is_submitted,
      :submitted_at,
      scores_attributes: %i[id question_id answer comment]
    )
  end

  def owns_response_or_map?
    # Member actions: we have @response from set_response
    return @response.map&.reviewer == current_user if @response&.map && current_user

    # Collection actions (create, next_action): check map ownership
    map_id = params[:response_map_id] || params[:map_id]
    return false if map_id.blank?

    map = ResponseMap.find_by(id: map_id)
    return false unless map

    map.reviewer == current_user
  end
end
