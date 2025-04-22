class Api::V1::StudentReviewController < ApplicationController
  # Constants for action names and roles to avoid magic strings
  LIST_ACTION     = 'list'.freeze
  SUBMITTER_ROLE  = 'submitter'.freeze

  # Ensure proper authorization and service initialization before actions
  before_action :authorize_user, only: [LIST_ACTION.to_sym]
  before_action :load_service, only: [:list]
  # Handle service-specific errors gracefully
  rescue_from 'StudentReviewService::Error', with: :handle_service_error

  # GET /api/v1/student_review/list
  # Returns a list of reviews for the authenticated student participant
  def list
    return unless authorized_participant?

    render json: build_review_response
  end

  private

  # Ensures the user has proper authorization to access the endpoint
  def authorize_user
    unless action_allowed?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
  end

  # Verifies that:
  # 1. The current user has student privileges
  # 2. The action being accessed is the list action
  # 3. The user has submitter role for the given resource
  def action_allowed?
    return false unless current_user_has_student_privileges?

    action_name == LIST_ACTION &&
      are_needed_authorizations_present?(params[:id], SUBMITTER_ROLE)
  end

  # Initializes the StudentReviewService with the participant ID
  # Handles any errors that occur during service initialization
  def load_service
    @service = StudentReviewService.new(params[:id])
  rescue StandardError => e
    render_error(e.message)
  end

  # Verifies that the current user matches the participant's user ID
  # Returns false and renders unauthorized error if verification fails
  def authorized_participant?
    if current_user_id?(@service.participant.user_id)
      check_bidding_redirect
      true
    else
      render json: { error: 'Unauthorized participant' }, status: :unauthorized
      false
    end
  end

  # Builds the complete review response JSON structure
  # Includes participant details, assignment info, and review statistics
  def build_review_response
    {
      participant: @service.participant,
      assignment: @service.assignment,
      topic_id: @service.topic_id,
      review_phase: @service.review_phase,
      review_mappings: @service.review_mappings,
      reviews: build_reviews_summary,
      response_ids: @service.response_ids
    }
  end

  # Constructs a summary of review statistics including:
  # - Total number of reviews
  # - Number of completed reviews
  # - Number of reviews in progress
  def build_reviews_summary
    {
      total: @service.num_reviews_total,
      completed: @service.num_reviews_completed,
      in_progress: @service.num_reviews_in_progress
    }
  end
  
  # Renders error messages with unprocessable entity status
  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  # TODO- implementation for review_bids has not been done yet
  # Handles redirection for review bidding functionality
  # Will be implemented in future iterations
  # def check_bidding_redirect
  #   if @service.bidding_enabled?
  #     redirect_to(
  #       controller: 'review_bids',
  #       action: 'index',
  #       assignment_id: params[:assignment_id],
  #       id: params[:id]
  #     ) and return
  #   end
  # end
end