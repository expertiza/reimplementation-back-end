class ReviewAllocator
  JOINED_TO_TOPIC = 'INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id'.freeze

  def initialize(assignment)
    @assignment = assignment
  end

  # ===== STATIC ASSIGNMENT =====
  def assign_statically(strategy_class)
    strategy_class.new(@assignment).each_review_pair { |reviewer, team| create_or_retrieve_mapping(reviewer, team) }
  end

  def assign_from_csv(csv_text)
    strategy = ReviewMappingStrategies::CsvImportStrategy.new(@assignment, csv_text)
    strategy.each_review_pair { |reviewer, team| create_or_retrieve_mapping(reviewer, team) }
  end

  def assign_random
    strategy = ReviewMappingStrategies::RandomStaticStrategy.new(@assignment)
    strategy.each_review_pair { |reviewer, team| create_or_retrieve_mapping(reviewer, team) }
  end

  # ===== DYNAMIC ASSIGNMENT =====

  # Assigns the reviewer to a submission using the given strategy class.
  # Unlike assign_eligible_review, this method is topic-agnostic and delegates
  # submission selection entirely to the strategy (e.g. least-reviewed submission).
  def assign_dynamically(strategy_class, reviewer)
    return nil unless can_accept_more_reviews?(reviewer)

    team = strategy_class.new(@assignment).assign_one(reviewer)
    return nil unless team

    create_or_retrieve_mapping(reviewer, team)
  end

  # Assigns the reviewer to review a submission on an eligible topic.
  # Eligible topics are those with at least one submission that has fewer than
  # min_count + threshold submitted reviews. When topic is nil, the strategy picks
  # the least-reviewed eligible submission automatically. When topic is given
  # (an explicit student choice), the strategy validates it and uses it directly.
  def assign_eligible_review(reviewer, topic: nil)
    return nil unless can_accept_more_reviews?(reviewer)

    team = ReviewMappingStrategies::LeastReviewedTopicStrategy.new(@assignment).assign_one(reviewer, topic: topic)
    return nil unless team

    create_or_retrieve_mapping(reviewer, team)
  end

  # Returns [eligible_topics_array, min_count] for display to the participant.
  # "Eligible" here means topics the participant can actually request right now:
  # - topics the participant owns or has already been assigned to review are excluded
  # - topics beyond min_count + review_topic_threshold are excluded (fairness window)
  # The threshold filter is intentional: showing only requestable topics prevents the UI
  # from listing a topic that the allocator would reject when the student actually requests it.
  # Returns ALL topics that survive both filters, sorted by ascending review count.
  def eligible_topics(participant)
    counts    = topic_review_counts
    min_count = ProjectTopic.where(assignment_id: @assignment.id).pluck(:id).map { |id| counts[id] || 0 }.min || 0
    [build_eligible_topic_list(participant, counts, min_count, @assignment.review_topic_threshold || 1), min_count]
  end

  def topic_eligible_for?(participant, topic)
    eligible_topics(participant).first.any? { |t| t[:id] == topic.id }
  end

  # ===== CALIBRATION =====

  def assign_calibration_reviews_round_robin
    instructor = AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: @assignment.instructor_id)
    return unless instructor

    calibration_team_ids = ReviewResponseMap
                           .where(reviewed_object_id: @assignment.id,
                                  reviewer_id: instructor.id, for_calibration: true)
                           .pluck(:reviewee_id)
    return if calibration_team_ids.empty?

    teams     = AssignmentTeam.where(id: calibration_team_ids)
    reviewers = AssignmentParticipant.where(parent_id: @assignment.id).where.not(user_id: @assignment.instructor_id)
    assign_round_robin(reviewers, teams, reviews_per_reviewer: 2, for_calibration: true)
  end

  # Returns the calibration reviews assigned to the given reviewer.
  def calibration_reviews_for(reviewer)
    ReviewResponseMap.where(reviewer_id: reviewer.id, for_calibration: true)
  end

  # Returns true if the reviewer has not yet reached num_reviews_allowed for this assignment.
  # When no cap is configured, always returns true.
  def can_accept_more_reviews?(reviewer)
    max = @assignment.num_reviews_allowed
    return true unless max

    ReviewResponseMap.where(reviewer_id: effective_reviewer_id(reviewer),
                            reviewed_object_id: @assignment.id).count < max
  end

  # ===== DELETION =====

  # Deletes a single review mapping by id.
  def delete_review_mapping(mapping_id)
    ReviewResponseMap.find(mapping_id).destroy
  end

  # Deletes all review mappings for the given reviewer on this assignment.
  def delete_all_reviews_by(reviewer)
    ReviewResponseMap.where(reviewer_id: effective_reviewer_id(reviewer),
                            reviewed_object_id: @assignment.id).destroy_all
  end

  private

  def assign_round_robin(reviewers, teams, reviews_per_reviewer: 1, for_calibration: false)
    reviewers.each_with_index do |reviewer, index|
      rid = effective_reviewer_id(reviewer)
      reviews_per_reviewer.times do |i|
        ReviewResponseMap.find_or_create_by!(
          reviewer_id: rid,
          reviewee_id: teams[(index + i) % teams.size].id,
          reviewed_object_id: @assignment.id, for_calibration: for_calibration
        ) { |m| m.reviewing_is_done_by_teams = @assignment.is_review_done_by_teams && reviewer.team.present? }
      end
    end
  end

  # Returns the number of submitted reviews per topic for this assignment,
  # keyed by project_topic_id. Only counts mappings that have a submitted response,
  # consistent with the allocation strategies that also count submitted reviews only.
  def topic_review_counts
    ReviewResponseMap.where(reviewed_object_id: @assignment.id)
                     .joins(:responses).where(responses: { is_submitted: true })
                     .joins(JOINED_TO_TOPIC).group('signed_up_teams.project_topic_id').count
  end

  def build_eligible_topic_list(participant, counts, min_count, threshold)
    rejected = excluded_topic_ids(participant)
    ProjectTopic.where(assignment_id: @assignment.id)
                .reject { |t| rejected.include?(t.id) }
                .select { |t| (counts[t.id] || 0) <= min_count + threshold }
                .map { |t| { id: t.id, topic_name: t.topic_name, review_count: counts[t.id] || 0 } }
                .sort_by { |t| t[:review_count] }
  end

  def excluded_topic_ids(participant)
    rid      = effective_reviewer_id(participant)
    reviewed = ReviewResponseMap.where(reviewer_id: rid, reviewed_object_id: @assignment.id)
                                .joins(JOINED_TO_TOPIC).distinct.pluck('signed_up_teams.project_topic_id')
    return Set.new(reviewed) if @assignment.can_review_same_topic

    own = SignedUpTeam.joins(:project_topic)
                      .find_by(team_id: participant.team&.id, project_topics: { assignment_id: @assignment.id })
                      &.project_topic_id
    Set.new(reviewed) | [own].compact
  end

  # Returns the id to use when querying ReviewResponseMap for this reviewer:
  # the reviewer's team id when the assignment uses team-based reviews, otherwise their own participant id.
  def effective_reviewer_id(reviewer)
    return reviewer.id unless reviewer.is_a?(AssignmentParticipant)
    return reviewer.id unless @assignment.is_review_done_by_teams

    reviewer.team&.id || reviewer.id
  end

  def create_or_retrieve_mapping(reviewer, team)
    ReviewResponseMap.find_or_create_by!(
      reviewer_id: effective_reviewer_id(reviewer), reviewee_id: team.id, reviewed_object_id: @assignment.id
    ) { |m| m.reviewing_is_done_by_teams = @assignment.is_review_done_by_teams && reviewer.team.present? }
  end
end
