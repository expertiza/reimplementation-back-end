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

  # Assigns reviewers to submissions in round-robin order using RoundRobinStrategy.
  def assign_round_robin
    ReviewAllocator.new(@assignment).assign_statically(ReviewMappingStrategies::RoundRobinStrategy)
    render json: { status: 'ok', message: 'Round-robin assignments created' }
  end

  # Assigns reviewers to submissions from a CSV upload.
  def assign_from_csv
    ReviewAllocator.new(@assignment).assign_from_csv(params[:csv].read)
    render json: { status: 'ok', message: 'CSV-based assignments created' }
  end

  # Assigns reviewers to submissions randomly.
  def assign_random
    ReviewAllocator.new(@assignment).assign_random
    render json: { status: 'ok', message: 'Random assignments created' }
  end

  # ===== DYNAMIC ASSIGNMENT =====

  # Assigns a reviewer to the submission with the fewest reviews (instructor-facing).
  def request_review_fewest
    strategy = ReviewMappingStrategies::LeastReviewedSubmissionStrategy
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    mapping  = ReviewAllocator.new(@assignment).assign_dynamically(strategy, reviewer)
    return render json: { status: 'error', message: 'No team available' }, status: :unprocessable_entity unless mapping

    render json: { status: 'ok', mapping_id: mapping.id }
  end

  # Assigns a reviewer to an eligible submission balanced across topics (instructor-facing).
  def request_review_topic_balance
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    mapping  = ReviewAllocator.new(@assignment).assign_eligible_review(reviewer)
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
    eligible, min_count = ReviewAllocator.new(@assignment).eligible_topics(participant)
    render json: { eligible_topics: eligible, threshold: threshold, min_review_count: min_count }
  end

  # POST /assignments/:assignment_id/review_mappings/request_review
  def request_review
    participant = current_participant
    return render json: { error: 'You are not a participant in this assignment' }, status: :forbidden unless participant

    handler = ReviewAllocator.new(@assignment)
    unless handler.can_accept_more_reviews?(participant)
      max = @assignment.num_reviews_allowed
      return render json: { error: "You cannot review more than #{max} submissions for this assignment." },
                    status: :unprocessable_entity
    end

    mapping = @assignment.topics? ? assign_topic_review(participant) : assign_submission_review(participant)
    return if performed?

    return render json: { error: 'No submissions available.' }, status: :unprocessable_entity unless mapping

    render json: { status: 'ok', mapping_id: mapping.id }
  end

  # ===== CALIBRATION =====

  # Assigns calibration reviews to all student participants in round-robin order.
  def assign_calibration_artifacts
    ReviewAllocator.new(@assignment).assign_calibration_reviews_round_robin
    render json: { status: 'ok', message: 'Calibration reviews assigned to all reviewers' }
  end

  # ===== DELETION =====

  # Deletes a single review mapping by id.
  def destroy
    ReviewAllocator.new(@assignment).delete_review_mapping(params[:id])
    render json: { status: 'ok', message: 'Mapping deleted' }
  end

  # Deletes all review mappings for a given reviewer on this assignment.
  def delete_all_for_reviewer
    ReviewAllocator.new(@assignment).delete_all_reviews_by(AssignmentParticipant.find(params[:reviewer_id]))
    render json: { status: 'ok', message: 'All mappings for reviewer deleted' }
  end

  # ===== INSTRUCTOR GRADING =====

  # Records the instructor's grade and comment for a completed review mapping.
  def assign_review_grade
    mapping = ReviewResponseMap.find(params[:id])
    mapping.assign_grade(grade: params[:grade], comment: params[:comment])
    render json: { status: 'ok', message: 'Review graded' }
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def current_participant
    AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: current_user.id)
  end

  def assign_topic_review(participant)
    handler = ReviewAllocator.new(@assignment)
    if @assignment.can_choose_topic_to_review && params[:topic_id].blank? && !params[:i_dont_care].present?
      return render json: { error: 'No topic selected.' }, status: :unprocessable_entity
    end

    return handler.assign_eligible_review(participant) unless params[:topic_id].present?

    topic = ProjectTopic.find_by(id: params[:topic_id].to_i, assignment_id: @assignment.id)
    return render json: { error: 'Topic not found.' }, status: :not_found unless topic

    # Guard kept even though the UI shows only eligible topics: API clients can POST
    # any topic_id directly, and a topic can become ineligible in the time between
    # the student fetching the eligible-topics list and submitting this request.
    unless handler.topic_eligible_for?(participant, topic)
      return render json: { error: 'This topic is not available for review at this time.' },
                    status: :unprocessable_entity
    end

    handler.assign_eligible_review(participant, topic: topic)
  end

  def assign_submission_review(participant)
    return render json: { error: 'Invalid topic.' }, status: :unprocessable_entity if params[:topic_id].present?

    ReviewAllocator.new(@assignment)
                   .assign_dynamically(ReviewMappingStrategies::LeastReviewedSubmissionStrategy, participant)
  end
end
