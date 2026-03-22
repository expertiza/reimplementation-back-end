# frozen_string_literal: true

class RevisionRequestsController < ApplicationController
  prepend_before_action :set_assignment, only: :index
  prepend_before_action :set_revision_request, only: %i[show update]

  def action_allowed?
    case params[:action]
    when 'index'
      current_user_has_instructor_privileges? && current_user_instructs_assignment?(@assignment)
    when 'show'
      return false unless @revision_request

      owns_revision_request? || current_user_instructs_assignment?(@revision_request.assignment)
    when 'update'
      return false unless @revision_request

      current_user_has_instructor_privileges? && current_user_instructs_assignment?(@revision_request.assignment)
    else
      false
    end
  end

  def index
    return if invalid_status_filter?

    revision_requests = RevisionRequest.where(assignment_id: @assignment.id)
    revision_requests = revision_requests.where(status: params[:status]) if params[:status].present?

    render json: revision_requests.order(created_at: :desc).map(&:as_json), status: :ok
  end

  def show
    return unless @revision_request

    render json: @revision_request.as_json, status: :ok
  end

  def update
    return render json: { error: 'This revision request has already been processed' }, status: :unprocessable_entity unless @revision_request.status == RevisionRequest::PENDING
    return if invalid_update_status?

    if @revision_request.update(update_params)
      render json: @revision_request.as_json, status: :ok
    else
      render json: { error: @revision_request.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def set_assignment
    @assignment = Assignment.find_by(id: params[:assignment_id])
    return if @assignment

    render json: { error: 'Assignment not found' }, status: :not_found
  end

  def set_revision_request
    @revision_request = RevisionRequest.find_by(id: params[:id])
    return if @revision_request

    render json: { error: 'Revision request not found' }, status: :not_found
  end

  def owns_revision_request?
    @revision_request.participant.user_id == current_user.id
  end

  def invalid_status_filter?
    return false if params[:status].blank? || RevisionRequest::STATUSES.include?(params[:status])

    render json: { error: 'Status must be PENDING, APPROVED, or DECLINED' }, status: :unprocessable_entity
    true
  end

  def invalid_update_status?
    return false if valid_resolved_status?

    render json: { error: 'Status must be APPROVED or DECLINED' }, status: :unprocessable_entity
    true
  end

  def valid_resolved_status?
    [RevisionRequest::APPROVED, RevisionRequest::DECLINED].include?(update_params[:status])
  end

  def update_params
    params.require(:revision_request).permit(:status, :response_comment)
  end
end
