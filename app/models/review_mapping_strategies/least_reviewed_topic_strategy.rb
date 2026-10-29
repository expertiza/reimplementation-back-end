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

    # Returns a hash of { topic_id => review_count } for all teams in this assignment,
    # by joining ReviewResponseMap through signed_up_teams to group at the topic level.
    def topic_review_counts
      ReviewResponseMap
        .where(reviewed_object_id: @assignment.id)
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

    # Returns a hash of { team_id => review_count } for all reviews on this assignment,
    # memoized so assign_one only issues this query once per strategy invocation.
    def team_review_counts
      @team_review_counts ||= ReviewResponseMap
                              .where(reviewed_object_id: @assignment.id)
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

    # Pass 2: keep only teams whose review count is within global_min + review_topic_threshold.
    # global_min is the fewest reviews any team in the assignment has (across all topics),
    # so the fairness window is consistent with the least-reviewed submission assignment-wide.
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
