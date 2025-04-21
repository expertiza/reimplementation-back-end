class Api::V1::StudentReviewController < ApplicationController
  before_action :authorize_user, only: [:list]
  before_action :load_service, only: [:list]

  def list
    return unless authorized_participant?

    render json: {
      participant: @service.participant,
      assignment: @service.assignment,
      topic_id: @service.topic_id,
      review_phase: @service.review_phase,
      review_mappings: @service.review_mappings,
      reviews: {
        total: @service.num_reviews_total,
        completed: @service.num_reviews_completed,
        in_progress: @service.num_reviews_in_progress
      },
      response_ids: @service.response_ids
    }
  end

  private

  def authorize_user
    unless action_allowed?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
  end

  def action_allowed?
    (current_user_has_student_privileges? &&
      (%w[list].include? action_name) &&
      are_needed_authorizations_present?(params[:id], 'submitter')) ||
    current_user_has_student_privileges?
  end

  def load_service
    @service = StudentReviewService.new(params[:id])
  end

  def authorized_participant?
    if current_user_id?(@service.participant.user_id)
      check_bidding_redirect
      true
    else
      render json: { error: 'Unauthorized participant' }, status: :unauthorized
      false
    end
  end

  def check_bidding_redirect
    if @service.bidding_enabled?
      redirect_to(
        controller: 'review_bids',
        action: 'index',
        assignment_id: params[:assignment_id],
        id: params[:id]
      ) and return
    end
  end
end