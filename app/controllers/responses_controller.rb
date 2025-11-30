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
      unless response_belongs_to? || current_user_has_admin_privileges? || 
             (current_user_has_instructor_privileges? && current_user_instructs_response_assignment?)
        render json: { error: 'forbidden' }, status: :forbidden
      end
    when 'unsubmit', 'destroy'
      # Only allow if user is the instructor of the associated assignment or has admin privileges
      unless current_user_has_admin_privileges? || 
             (current_user_has_instructor_privileges? && current_user_instructs_response_assignment?)
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
      render json: { message: "#{response_map_label} submission started successfully", response: @response }, status: :created
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id
  # Reviewer edits existing draft (still unsubmitted)
  def update
    return render json: { error: 'forbidden' }, status: :forbidden if @response.is_submitted?

    if @response.update(response_params)
      render json: { message: "#{response_map_label} submission saved successfully", response: @response }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/submit
  # Lock the response and calculate final score
  def submit
    return render json: { error: 'Submission not found' }, status: :not_found unless @response
    if @response.is_submitted?
      return render json: { error: 'Submission has already been locked' }, status: :unprocessable_entity
    end
    # Check deadline
    unless submission_window_open?(@response)
      return render json: { error: 'Submission deadline has passed' }, status: :forbidden
    end

    # Lock response
    @response.is_submitted = true

    # Calculate score via ScorableHelper
    total_score = @response.aggregate_questionnaire_score

    if @response.save
      render json: {
        message: "#{response_map_label} submission locked and scored successfully",
        response: @response,
        total_score: total_score
      }, status: :ok
    else
      render json: { error: @response.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # PATCH /responses/:id/unsubmit
  # Instructor/Admin reopens a submitted response for further editing
  def unsubmit
    return render json: { error: "#{response_map_label} submission not found" }, status: :not_found unless @response

    if @response.is_submitted?
      @response.update(is_submitted: false)
      render json: { message: "#{response_map_label} submission reopened for edits. The reviewer can now make changes.", response: @response }, status: :ok
    else
      render json: { error: "This #{response_map_label.downcase} submission is not locked, so it cannot be reopened" }, status: :unprocessable_entity
    end
  end

  # DELETE /responses/:id
  # Instructor/Admin deletes invalid/test response
  def destroy
    return render json: { error: 'Submission not found' }, status: :not_found unless @response

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

  def response_belongs_to?
    # Member actions: we have @response from set_response
    return @response.map&.reviewer&.id == current_user.id if @response&.map&.reviewer && current_user

    # Collection actions (create, next_action): check map ownership
    map_id = params[:response_map_id] || params[:map_id]
    return false if map_id.blank?

    map = ResponseMap.find_by(id: map_id)
    return false unless map

    map.reviewer == current_user
  end

  # Checks whether the current_user is the instructor for the assignment
  # associated with the response identified by params[:id].
  # Uses the shared authorization method from Authorization concern.
  def current_user_instructs_response_assignment?
    resp = Response.find_by(id: params[:id])
    return false unless resp&.response_map

    assignment = resp.response_map&.assignment
    return false unless assignment

    # Delegate to the shared authorization helper
    current_user_instructs_assignment?(assignment)
  end

  # Returns the friendly label for the response's map type (e.g., "Review", "Assignment Survey")
  # Falls back to a generic "Submission" if the label cannot be determined.
  def response_map_label
    return 'Submission' unless @response&.response_map

    map_label = @response.response_map&.response_map_label
    map_label.presence || 'Submission'
  end

  # Returns true if the assignment's due date is in the future or no due date is set
  def submission_window_open?(response)
    assignment = response&.response_map&.assignment
    return true if assignment.nil?
    return true if assignment.due_dates.nil?
    
    # Check if due_date has a future? method, otherwise compare timestamps
    due_dates = assignment.due_dates
    if due_dates.respond_to?(:future?)
      return due_dates.first.future?
    end

    # Fallback: compare timestamps
    return true if due_dates.first.nil?
    
    due_dates.first.due_at > Time.current
  end
end
