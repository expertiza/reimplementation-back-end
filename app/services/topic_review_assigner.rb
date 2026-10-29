# frozen_string_literal: true

# Encapsulates all topic-based review assignment logic for a single assignment.
# The controller calls the two public methods and renders based on the returned values;
# this class never touches the request/response cycle directly.
class TopicReviewAssigner
  Result = Struct.new(:ok, :mapping, :error, :http_status, keyword_init: true) do
    def ok? = ok
  end
  def initialize(assignment)
    @assignment = assignment
  end

  # Returns [eligible_topics_array, min_review_count].
  # eligible_topics_array: { id:, topic_name:, review_count: } hashes sorted by count,
  # excluding topics the participant owns or has already reviewed, capped at
  # min_count + threshold.
  def eligible_topics(participant, threshold:)
    counts    = topic_review_counts
    min_count = min_review_count(counts)
    [build_eligible_topics(participant, counts, min_count, threshold), min_count]
  end

  # Assigns a peer review for the participant.
  # When topic_id is present, assigns the participant to an eligible team under that
  # topic; otherwise picks the least-reviewed eligible topic automatically.
  # When must_choose is true and neither topic_id nor i_dont_care is given, returns
  # an error Result so the student is prompted to select a topic.
  # Returns a Result (ok? == true with a mapping, or ok? == false with error details).
  def assign(participant, topic_id: nil, must_choose: false, i_dont_care: false)
    if must_choose && topic_id.blank? && !i_dont_care
      return Result.new(ok: false, http_status: :unprocessable_entity, error: 'No topic selected.')
    end

    topic_id.present? ? assign_explicit(participant, topic_id.to_i) : assign_automatic(participant)
  end

  private

  def assign_explicit(participant, topic_id)
    topic = ProjectTopic.find_by(id: topic_id, assignment_id: @assignment.id)
    return Result.new(ok: false, error: 'Topic not found.', http_status: :not_found) unless topic

    validation = validate_for_explicit(participant, topic)
    return validation if validation

    mapping = create_mapping_for_topic(participant, topic)
    unless mapping
      return Result.new(ok: false, http_status: :unprocessable_entity,
                        error: 'No submissions available for this topic. Please try another topic.')
    end

    Result.new(ok: true, mapping: mapping)
  end

  def validate_for_explicit(participant, topic)
    unless ReviewMappingHandler.new(@assignment).can_accept_more_reviews?(participant)
      return Result.new(ok: false, http_status: :unprocessable_entity,
                        error: 'You have too many open reviews. Please submit existing reviews first.')
    end

    threshold = @assignment.review_topic_threshold || 1
    counts    = topic_review_counts
    eligible  = build_eligible_topics(participant, counts, min_review_count(counts), threshold)
    return if eligible.any? { |t| t[:id] == topic.id }

    Result.new(ok: false, http_status: :unprocessable_entity,
               error: 'This topic is not available for review at this time.')
  end

  def assign_automatic(participant)
    threshold = @assignment.review_topic_threshold || 1
    mapping   = ReviewMappingHandler.new(@assignment).assign_dynamic_topic_fairly(participant, k: threshold)
    return Result.new(ok: true, mapping: mapping) if mapping

    Result.new(ok: false, http_status: :unprocessable_entity,
               error: 'No topics available to review at this time. Please try later.')
  end

  def create_mapping_for_topic(participant, topic)
    reviewer_id    = reviewer_id_for(participant)
    eligible_teams = eligible_teams_for_topic(topic, participant, reviewer_id)
    return nil if eligible_teams.empty?

    counts = topic_review_counts
    team   = eligible_teams.min_by { |t| counts[t.id] || 0 }
    ReviewResponseMap.find_or_create_by!(
      reviewer_id: reviewer_id, reviewee_id: team.id, reviewed_object_id: @assignment.id
    ) { |m| m.reviewing_is_done_by_teams = @assignment.is_review_done_by_teams && participant.team.present? }
  end

  def reviewer_id_for(participant)
    @assignment.is_review_done_by_teams ? participant.team&.id || participant.id : participant.id
  end

  # Per-topic review count across all submissions for this assignment.
  # Only valid for team-based assignments; callers guard on has_teams.
  def topic_review_counts
    ReviewResponseMap.where(reviewed_object_id: @assignment.id)
                     .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
                     .group('signed_up_teams.project_topic_id').count
  end

  # Returns the topic ID the participant has signed up for, or nil.
  def own_topic_id_for(participant)
    SignedUpTeam.joins(:project_topic)
                .find_by(team_id: participant.team&.id, project_topics: { assignment_id: @assignment.id })
                &.project_topic_id
  end

  def already_reviewed_topic_ids(reviewer_id)
    ReviewResponseMap.where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
                     .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
                     .distinct.pluck('signed_up_teams.project_topic_id')
  end

  def min_review_count(counts)
    ProjectTopic.where(assignment_id: @assignment.id).pluck(:id).map { |id| counts[id] || 0 }.min || 0
  end

  def excluded_topic_ids(participant)
    own_topic = @assignment.can_review_same_topic ? [] : [own_topic_id_for(participant)].compact
    Set.new(already_reviewed_topic_ids(reviewer_id_for(participant))) | own_topic
  end

  def build_eligible_topics(participant, counts, min_count, threshold)
    rejected = excluded_topic_ids(participant)
    ProjectTopic.where(assignment_id: @assignment.id)
                .reject { |t| rejected.include?(t.id) }
                .select { |t| (counts[t.id] || 0) <= min_count + threshold }
                .map    { |t| { id: t.id, topic_name: t.topic_name, review_count: counts[t.id] || 0 } }
                .sort_by { |t| t[:review_count] }
  end

  def eligible_teams_for_topic(topic, participant, reviewer_id)
    member_team_ids   = TeamsParticipant.where(participant_id: participant.id).pluck(:team_id)
    reviewed_team_ids = ReviewResponseMap.where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
                                         .pluck(:reviewee_id)
    topic.teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: false })
         .where.not(id: (member_team_ids + reviewed_team_ids).uniq)
  end
end
