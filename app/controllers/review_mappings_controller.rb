class ReviewMappingsController < ApplicationController
  include Authorization
  before_action :set_assignment
  before_action :authorize

  # ===== STATIC ASSIGNMENT =====
  def assign_round_robin
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_statically(ReviewMappingStrategies::RoundRobinStrategy)
    render json: { status: "ok", message: "Round-robin assignments created" }
  end

  def assign_from_csv
    csv_text = params[:csv].read # file upload
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_from_csv(csv_text)
    render json: { status: "ok", message: "CSV-based assignments created" }
  end

    # POST /assignments/:assignment_id/review_mappings/random
    def assign_random
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_random
    render json: { status: "ok", message: "Random assignments created" }
    end


  # ===== DYNAMIC ASSIGNMENT =====
  def request_review_fewest
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamically(
      ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
      reviewer
    )

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No team available or limit reached" }, status: :unprocessable_entity
    end
  end

  def request_review_topic_balance
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamic_topic_fairly(reviewer, k: params[:k].to_i)

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No eligible topic/team available" }, status: :unprocessable_entity
    end
  end

  # ===== STUDENT-FACING DYNAMIC REVIEW =====

  # GET /assignments/:assignment_id/review_mappings/eligible_topics
  # Returns the topics a student may choose from for dynamic review.
  # A topic is eligible when its review count is within K of the fewest-reviewed
  # topic, and the student hasn't already reviewed it or submitted to it.
  def eligible_topics
    participant = current_participant
    return render json: { error: 'Not a participant' }, status: :forbidden unless participant
    return render json: { error: 'This assignment does not have topics' }, status: :unprocessable_entity unless @assignment.topics?

    k               = @assignment.review_topic_threshold || 1
    counts_by_topic = topic_review_counts
    min_count       = counts_by_topic.values.min || 0
    eligible        = build_eligible_topics(participant, counts_by_topic, min_count, k)

    render json: { eligible_topics: eligible, threshold: k, min_review_count: min_count }
  end

  # POST /assignments/:assignment_id/review_mappings/request_review
  # Student requests a review assignment. For assignments with topics and
  # can_choose_topic_to_review?, a topic_id must be provided unless i_dont_care is set.
  def request_review
    participant = current_participant
    return render json: { error: 'Not a participant' }, status: :forbidden unless participant

    reviewer_id = participant_reviewer_id(participant)

    if @assignment.num_reviews_allowed.to_i.positive?
      current_count = ReviewResponseMap.where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id).count
      if current_count >= @assignment.num_reviews_allowed
        return render json: {
          error: "You cannot do more than #{@assignment.num_reviews_allowed} reviews based on assignment policy"
        }, status: :unprocessable_entity
      end
    end

    mapping = if @assignment.topics?
                assign_review_with_topic(participant, reviewer_id)
              else
                assign_review_no_topic(participant)
              end

    return unless mapping.is_a?(ReviewResponseMap)

    render json: { status: 'ok', mapping_id: mapping.id }
  end

  # ===== CALIBRATION =====
  def assign_calibration_artifacts
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_calibration_reviews_round_robin
    render json: { status: "ok", message: "Calibration reviews assigned to all reviewers" }
  end

  # ===== DELETE =====
  def destroy
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_review_mapping(params[:id])
    render json: { status: "ok", message: "Mapping deleted" }
  end

  def delete_all_for_reviewer
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_all_reviews_for(reviewer)
    render json: { status: "ok", message: "All mappings for reviewer deleted" }
  end

  # ===== INSTRUCTOR GRADING =====
  def grade_review
    mapping = ReviewResponseMap.find(params[:mapping_id])
    handler = ReviewMappingHandler.new(@assignment)

    handler.grade_review(mapping, grade: params[:grade], comment: params[:comment])
    render json: { status: "ok", message: "Review graded" }
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def current_participant
    AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: current_user.id)
  end

  # When reviews are done by teams, the reviewer ID is the team ID.
  def participant_reviewer_id(participant)
    @assignment.is_review_done_by_teams ? participant.team&.id || participant.id : participant.id
  end

  # Per-topic review count across all submissions for this assignment.
  def topic_review_counts
    ReviewResponseMap
      .where(reviewed_object_id: @assignment.id)
      .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
      .group('signed_up_teams.project_topic_id')
      .count
  end

  # Returns the topic ID the participant has signed up for, or nil.
  def own_topic_id_for(participant)
    SignedUpTeam.joins(:project_topic)
                .find_by(team_id: participant.team&.id, project_topics: { assignment_id: @assignment.id })
                &.project_topic_id
  end

  # Returns topic IDs this reviewer has already reviewed for this assignment.
  def already_reviewed_topic_ids(reviewer_id)
    ReviewResponseMap
      .where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
      .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
      .pluck('signed_up_teams.project_topic_id')
      .uniq
  end

  # Builds the sorted list of eligible topics for dynamic review selection.
  def build_eligible_topics(participant, counts_by_topic, min_count, k)
    reviewer_id        = participant_reviewer_id(participant)
    excluded_own       = own_topic_id_for(participant)
    excluded_reviewed  = already_reviewed_topic_ids(reviewer_id)

    ProjectTopic
      .where(assignment_id: @assignment.id)
      .reject { |t| t.id == excluded_own || excluded_reviewed.include?(t.id) }
      .select { |t| (counts_by_topic[t.id] || 0) <= min_count + k }
      .map    { |t| { id: t.id, topic_name: t.topic_name, review_count: counts_by_topic[t.id] || 0 } }
      .sort_by { |t| t[:review_count] }
  end

  # Handles dynamic assignment for topic-based assignments.
  def assign_review_with_topic(participant, reviewer_id)
    if @assignment.can_choose_topic_to_review && params[:topic_id].blank? && params[:i_dont_care].blank?
      render json: { error: 'No topic selected. Please go back and select a topic.' }, status: :unprocessable_entity
      return nil
    end

    if params[:topic_id].present?
      topic = ProjectTopic.find_by(id: params[:topic_id], assignment_id: @assignment.id)
      unless topic
        render json: { error: 'Topic not found or not part of this assignment' }, status: :not_found
        return nil
      end
      assign_review_for_topic(participant, reviewer_id, topic)
    else
      k       = @assignment.review_topic_threshold || 1
      handler = ReviewMappingHandler.new(@assignment)
      mapping = handler.assign_dynamic_topic_fairly(participant, k: k)
      unless mapping
        render json: { error: 'No topics available to review at this time. Please try later.' }, status: :unprocessable_entity
        return nil
      end
      mapping
    end
  end

  # Finds an eligible team in the given topic and creates the mapping.
  def assign_review_for_topic(participant, reviewer_id, topic)
    eligible_teams = topic.teams
                          .joins(:signed_up_teams)
                          .where(signed_up_teams: { is_waitlisted: false })
                          .reject { |team| team.participants.include?(participant) }
                          .reject { |team|
                            ReviewResponseMap.exists?(
                              reviewer_id:        reviewer_id,
                              reviewee_id:        team.id,
                              reviewed_object_id: @assignment.id
                            )
                          }

    if eligible_teams.empty?
      render json: { error: 'No submissions available for this topic. Please try another topic.' }, status: :unprocessable_entity
      return nil
    end

    counts = topic_review_counts
    team   = eligible_teams.min_by { |t| counts[t.id] || 0 }

    ReviewResponseMap.find_or_create_by!(
      reviewer_id:        reviewer_id,
      reviewee_id:        team.id,
      reviewed_object_id: @assignment.id
    )
  end

  # Handles dynamic assignment for assignments without topics.
  def assign_review_no_topic(participant)
    handler = ReviewMappingHandler.new(@assignment)
    mapping = handler.assign_dynamically(ReviewMappingStrategies::LeastReviewedSubmissionStrategy, participant)
    unless mapping
      render json: { error: 'No artifacts available to review at this time. Please try later.' }, status: :unprocessable_entity
      return nil
    end
    mapping
  end
end
