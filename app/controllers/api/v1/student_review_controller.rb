class Api::V1::StudentReviewController < ApplicationController
  LIST_ACTION     = 'list'.freeze
  SUBMITTER_ROLE  = 'submitter'.freeze

  before_action :authorize_user, only: [LIST_ACTION.to_sym]
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

  # Add this method to handle locale
  def controller_locale
    # Use the user's locale preference if available
    if current_user && current_user.locale.present?
      I18n.locale = current_user.locale
    else
      # Fall back to default locale
      I18n.locale = I18n.default_locale
    end
  end

  # Quick-exit unless they're a student.
  # Then, only allow the LIST_ACTION for users who also have the SUBMITTER_ROLE on this resource.
  def action_allowed?
    # guard clause: must be a student at all
    return false unless current_user_has_student_privileges?  # early return

    # only permit “list” for submitters
    action_name == LIST_ACTION &&
      are_needed_authorizations_present?(params[:id], SUBMITTER_ROLE)
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