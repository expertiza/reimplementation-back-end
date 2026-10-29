# frozen_string_literal: true

class ReviewMappingsController < ApplicationController
  include Authorization
  before_action :set_assignment
  before_action :authorize

  def action_allowed?
    return current_user_has_student_privileges? if %w[eligible_topics request_review].include?(action_name)

    current_user_teaching_staff_of_assignment?(@assignment.id)
  end

  # ===== STATIC ASSIGNMENT =====

  def assign_round_robin
    ReviewMappingHandler.new(@assignment).assign_statically(ReviewMappingStrategies::RoundRobinStrategy)
    render json: { status: 'ok', message: 'Round-robin assignments created' }
  end

  def assign_from_csv
    ReviewMappingHandler.new(@assignment).assign_from_csv(params[:csv].read)
    render json: { status: 'ok', message: 'CSV-based assignments created' }
  end

  def assign_random
    ReviewMappingHandler.new(@assignment).assign_random
    render json: { status: 'ok', message: 'Random assignments created' }
  end

  # ===== DYNAMIC ASSIGNMENT =====

  def request_review_fewest
    strategy = ReviewMappingStrategies::LeastReviewedSubmissionStrategy
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    mapping  = ReviewMappingHandler.new(@assignment).assign_dynamically(strategy, reviewer)
    return render json: { status: 'error', message: 'No team available' }, status: :unprocessable_entity unless mapping

    render json: { status: 'ok', mapping_id: mapping.id }
  end

  def request_review_topic_balance
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    mapping  = ReviewMappingHandler.new(@assignment).assign_dynamic_topic_fairly(reviewer, k: params[:k].to_i)
    return render json: { status: 'error', message: 'No eligible topic' }, status: :unprocessable_entity unless mapping

    render json: { status: 'ok', mapping_id: mapping.id }
  end

  # ===== STUDENT-FACING DYNAMIC REVIEW =====

  # GET /assignments/:assignment_id/review_mappings/eligible_topics
  def eligible_topics
    participant = current_participant
    return render json: { error: 'You are not a participant in this assignment' }, status: :forbidden unless participant
    unless @assignment.topics?
      return render json: { error: 'This assignment does not have topics' }, status: :unprocessable_entity
    end

    threshold = @assignment.review_topic_threshold || 1
    eligible, min_count = TopicReviewAssigner.new(@assignment).eligible_topics(participant, threshold: threshold)
    render json: { eligible_topics: eligible, threshold: threshold, min_review_count: min_count }
  end

  # POST /assignments/:assignment_id/review_mappings/request_review
  def request_review
    participant = current_participant
    return render json: { error: 'You are not a participant in this assignment' }, status: :forbidden unless participant
    return unless can_review_additional_submissions?(participant)

    if @assignment.topics?
      result = TopicReviewAssigner.new(@assignment)
                                  .assign(participant, topic_id: params[:topic_id],
                                                       must_choose: @assignment.can_choose_topic_to_review,
                                                       i_dont_care: params[:i_dont_care].present?)
      return render json: { error: result.error }, status: result.http_status unless result.ok?

      render json: { status: 'ok', mapping_id: result.mapping.id }
    else
      return render json: { error: 'Invalid topic.' }, status: :unprocessable_entity if params[:topic_id].present?

      strategy = ReviewMappingStrategies::LeastReviewedSubmissionStrategy
      mapping  = ReviewMappingHandler.new(@assignment).assign_dynamically(strategy, participant)
      return render json: { error: 'No submissions available.' }, status: :unprocessable_entity unless mapping

      render json: { status: 'ok', mapping_id: mapping.id }
    end
  end

  # ===== CALIBRATION =====

  def assign_calibration_artifacts
    ReviewMappingHandler.new(@assignment).assign_calibration_reviews_round_robin
    render json: { status: 'ok', message: 'Calibration reviews assigned to all reviewers' }
  end

  # ===== DELETE =====

  def destroy
    ReviewMappingHandler.new(@assignment).delete_review_mapping(params[:id])
    render json: { status: 'ok', message: 'Mapping deleted' }
  end

  def delete_all_for_reviewer
    ReviewMappingHandler.new(@assignment).delete_all_reviews_for(AssignmentParticipant.find(params[:reviewer_id]))
    render json: { status: 'ok', message: 'All mappings for reviewer deleted' }
  end

  # ===== INSTRUCTOR GRADING =====

  def grade_review
    mapping = ReviewResponseMap.find(params[:mapping_id])
    ReviewMappingHandler.new(@assignment).grade_review(mapping, grade: params[:grade], comment: params[:comment])
    render json: { status: 'ok', message: 'Review graded' }
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def current_participant
    AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: current_user.id)
  end

  # Returns true when the student is allowed to submit another review,
  # false (and renders a 422) when they have reached the assignment's review limit.
  def can_review_additional_submissions?(participant)
    return true unless @assignment.num_reviews_allowed.to_i.positive?

    reviewer_id = @assignment.is_review_done_by_teams ? participant.team&.id || participant.id : participant.id
    count = ReviewResponseMap.where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id).count
    return true if count < @assignment.num_reviews_allowed

    msg = "You cannot do more than #{@assignment.num_reviews_allowed} reviews for this assignment."
    render json: { error: msg }, status: :unprocessable_entity
    false
  end
end
