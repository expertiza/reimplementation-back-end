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
    unless participant
      return render json: { error: 'You are not a participant in this assignment.' }, status: :forbidden
    end
    unless @assignment.topics?
      return render json: { error: 'This assignment does not have topics' }, status: :unprocessable_entity
    end

    threshold = @assignment.review_topic_threshold || 1
    counts    = topic_review_counts
    min_count = counts.values.min || 0
    eligible  = build_eligible_topics(participant, counts, min_count, threshold)

    render json: { eligible_topics: eligible, threshold: threshold, min_review_count: min_count }
  end

  # POST /assignments/:assignment_id/review_mappings/request_review
  # Student requests a review assignment. For assignments with topics and
  # can_choose_topic_to_review?, a topic_id must be provided unless i_dont_care is set.
  def request_review
    participant = current_participant
    unless participant
      return render json: { error: 'You are not a participant in this assignment.' }, status: :forbidden
    end

    return if check_review_limit(participant)

    new_response_map = if @assignment.topics?
                         handle_topic_review_request(participant)
                       else
                         assign_review_no_topic(participant)
                       end

    return if new_response_map.nil?

    render json: { status: 'ok', mapping_id: new_response_map.id }
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

  # Returns true (and renders an error) when the student has reached the review limit.
  def check_review_limit(participant)
    return false unless @assignment.num_reviews_allowed.to_i.positive?

    reviewer_id = participant_reviewer_id(participant)
    num_reviews_currently_assigned = ReviewResponseMap
                                     .where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
                                     .count
    return false if num_reviews_currently_assigned < @assignment.num_reviews_allowed

    render json: {
      error: "You cannot do more than #{@assignment.num_reviews_allowed} reviews for this assignment."
    }, status: :unprocessable_entity
    true
  end

  def handle_topic_review_request(participant)
    if @assignment.can_choose_topic_to_review && params[:topic_id].blank? && params[:i_dont_care].blank?
      render json: { error: 'No topic selected. Please go back and select a topic.' },
             status: :unprocessable_entity
      return nil
    end

    params[:topic_id].present? ? assign_explicit_topic(participant) : assign_automatic_topic(participant)
  end

  def assign_explicit_topic(participant)
    topic = ProjectTopic.find_by(id: params[:topic_id], assignment_id: @assignment.id)
    unless topic
      render json: { error: 'Topic not found.' }, status: :not_found
      return nil
    end

    mapping = assign_review_for_topic(participant, topic)
    unless mapping
      render json: { error: 'No submissions available for this topic. Please try another topic.' },
             status: :unprocessable_entity
      return nil
    end
    mapping
  end

  def assign_automatic_topic(participant)
    # threshold (k): topics with at most (min_reviews + threshold) reviews are eligible
    threshold = @assignment.review_topic_threshold || 1
    mapping   = ReviewMappingHandler.new(@assignment).assign_dynamic_topic_fairly(participant, k: threshold)
    unless mapping
      render json: { error: 'No topics available to review at this time. Please try later.' },
             status: :unprocessable_entity
      return nil
    end
    mapping
  end

  def assign_review_no_topic(participant)
    mapping = ReviewMappingHandler.new(@assignment)
                                  .assign_dynamically(
                                    ReviewMappingStrategies::LeastReviewedSubmissionStrategy, participant
                                  )
    unless mapping
      render json: { error: 'No artifacts available to review at this time. Please try later.' },
             status: :unprocessable_entity
      return nil
    end
    mapping
  end

  # Per-topic review count across all submissions for this assignment.
  # Note: uses signed_up_teams join, so only accurate for team-based assignments.
  def topic_review_counts
    ReviewResponseMap
      .where(reviewed_object_id: @assignment.id)
      .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
      .group('signed_up_teams.project_topic_id')
      .count
  end

  def own_topic_id_for(participant)
    SignedUpTeam.joins(:project_topic)
                .find_by(team_id: participant.team&.id, project_topics: { assignment_id: @assignment.id })
                &.project_topic_id
  end

  def already_reviewed_topic_ids(reviewer_id)
    ReviewResponseMap
      .where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
      .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
      .pluck('signed_up_teams.project_topic_id')
      .uniq
  end

  def excluded_topic_ids(participant)
    reviewer_id = participant_reviewer_id(participant)
    own         = own_topic_id_for(participant)
    reviewed    = already_reviewed_topic_ids(reviewer_id)
    Set.new(reviewed) | [own].compact
  end

  def build_eligible_topics(participant, counts, min_count, threshold)
    rejected = excluded_topic_ids(participant)
    ProjectTopic
      .where(assignment_id: @assignment.id)
      .reject { |t| rejected.include?(t.id) }
      .select { |t| (counts[t.id] || 0) <= min_count + threshold }
      .map    { |t| { id: t.id, topic_name: t.topic_name, review_count: counts[t.id] || 0 } }
      .sort_by { |t| t[:review_count] }
  end

  def eligible_teams_for_topic(topic, participant, reviewer_id)
    member_team_ids   = TeamsParticipant.where(participant_id: participant.id).pluck(:team_id)
    reviewed_team_ids = ReviewResponseMap
                        .where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
                        .pluck(:reviewee_id)
    excluded_ids = (member_team_ids + reviewed_team_ids).uniq

    topic.teams
         .joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: false })
         .where.not(id: excluded_ids)
  end

  # Finds an eligible team to review that has the given topic, and creates the mapping.
  def assign_review_for_topic(participant, topic)
    reviewer_id    = participant_reviewer_id(participant)
    eligible_teams = eligible_teams_for_topic(topic, participant, reviewer_id)
    return nil if eligible_teams.empty?

    counts = topic_review_counts
    team   = eligible_teams.min_by { |t| counts[t.id] || 0 }
    ReviewResponseMap.find_or_create_by!(
      reviewer_id: reviewer_id,
      reviewee_id: team.id,
      reviewed_object_id: @assignment.id
    )
  end
end
