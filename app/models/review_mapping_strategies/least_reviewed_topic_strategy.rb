require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedTopicStrategy < BaseStrategy
    # Assign reviewer to review a team in a topic-balanced way.
    # When topic is nil, picks the topic with the fewest reviews within review_topic_threshold
    # of the minimum (automatic). When topic is given, uses it directly (explicit student choice).
    # In both cases selects the team within that topic with the fewest reviews.
    # Returns nil if no eligible topic or team is available.
    def assign_one(reviewer, topic: nil)
      topic_counts = topic_review_counts
      topic        ||= eligible_topic(topic_counts)
      return nil unless topic

      t_counts = team_review_counts
      eligible_teams_on_topic(reviewer, topic, t_counts).min_by { |t| t_counts[t.id] || 0 }
    end

    private

    # Returns the number of submitted reviews per topic for this assignment,
    # keyed by project_topic_id. Only counts mappings that have a submitted response.
    def topic_review_counts
      ReviewResponseMap
        .where(reviewed_object_id: @assignment.id)
        .joins(:responses).where(responses: { is_submitted: true })
        .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
        .group('signed_up_teams.project_topic_id')
        .count
    end

    # Returns the ProjectTopic with the fewest reviews that is still within
    # review_topic_threshold of the global minimum review count across all topics.
    # Returns nil if no topics exist.
    def eligible_topic(counts)
      threshold = @assignment.review_topic_threshold || 0
      all_ids   = ProjectTopic.where(assignment_id: @assignment.id).pluck(:id)
      min_count = all_ids.map { |id| count_for(counts, id) }.min || 0
      topic_id  = all_ids.select { |id| count_for(counts, id) <= min_count + threshold }
                         .min_by { |id| count_for(counts, id) }
      topic_id && ProjectTopic.find_by(id: topic_id)
    end

    # Safe lookup into a review-count hash; returns 0 when the id has no reviews yet.
    def count_for(counts, id)
      counts[id] || 0
    end

    # Returns the number of submitted reviews per team for this assignment,
    # keyed by reviewee_id. Only counts mappings that have a submitted response.
    # Result is cached on first call so repeated use within one strategy instance
    # does not issue additional queries.
    def team_review_counts
      @team_review_counts ||= ReviewResponseMap
                              .where(reviewed_object_id: @assignment.id)
                              .joins(:responses).where(responses: { is_submitted: true })
                              .group(:reviewee_id)
                              .count
    end

    # Returns teams within `topic` that a reviewer can be assigned to.
    # Two-pass filter:
    # 1. Remove self-review, duplicates, and teams at the hard cap (max_reviews_per_submission).
    # 2. Of what remains, keep only teams within min_count + review_topic_threshold
    #    (the fairness window), where min_count is the fewest reviews any remaining team has.
    def eligible_teams_on_topic(reviewer, topic, team_counts)
      base = base_eligible_teams(reviewer, topic)
      apply_threshold_window(base, team_counts)
    end

    # Pass 1: exclude the reviewer's own team, already-assigned teams, and teams at the hard cap.
    def base_eligible_teams(reviewer, topic)
      rid = effective_reviewer_id(reviewer)
      topic.teams.reject do |team|
        team.participants.include?(reviewer) ||
          ReviewResponseMap.exists?(reviewer_id: rid, reviewee_id: team.id,
                                    reviewed_object_id: @assignment.id) ||
          review_cap_reached?(team)
      end
    end

    # Pass 2: keep only teams whose submitted-review count is within the fairness window.
    # The window upper bound is global_min + review_topic_threshold, where global_min is
    # the minimum review count across ALL teams in the assignment, not just the teams on
    # this particular topic. Using the assignment-wide minimum prevents a topic where every
    # team already has many reviews from continuing to generate new assignments just because
    # its local minimum is high; the window stays anchored to the least-reviewed team
    # anywhere in the assignment.
    def apply_threshold_window(teams, team_counts)
      threshold  = @assignment.review_topic_threshold || 0
      global_min = @assignment.teams.map { |t| team_counts[t.id] || 0 }.min || 0
      teams.reject { |team| (team_counts[team.id] || 0) > global_min + threshold }
    end

    # Returns true if the team has already received the maximum number of reviews
    # allowed per submission (max_reviews_per_submission on the assignment).
    def review_cap_reached?(team)
      max = @assignment.max_reviews_per_submission
      max && ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: @assignment.id).count >= max
    end
  end
end
