require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedTopicStrategy < BaseStrategy
    # Assign reviewer to review a team in the least-reviewed topic within the k threshold.
    # Picks the eligible topic with the fewest reviews (within k of the minimum),
    # then selects the team in that topic with the fewest reviews.
    # Returns nil if no eligible topic or team is available.
    def assign_one(reviewer, k: 1)
      counts = topic_review_counts
      topic  = eligible_topic(counts, k)
      return nil unless topic

      teams_eligible_for_review(reviewer, topic).min_by { |t| count_for(counts, t.id) }
    end

    private

    def topic_review_counts
      ReviewResponseMap
        .where(reviewed_object_id: @assignment.id)
        .joins('INNER JOIN signed_up_teams ON signed_up_teams.team_id = response_maps.reviewee_id')
        .group('signed_up_teams.project_topic_id')
        .count
    end

    def eligible_topic(counts, k)
      all_ids   = ProjectTopic.where(assignment_id: @assignment.id).pluck(:id)
      min_count = all_ids.map { |id| count_for(counts, id) }.min || 0
      topic_id  = all_ids.select { |id| count_for(counts, id) <= min_count + k }
                         .min_by { |id| count_for(counts, id) }
      topic_id && ProjectTopic.find_by(id: topic_id)
    end

    def count_for(counts, id)
      counts[id] || 0
    end

    def teams_eligible_for_review(reviewer, topic)
      rid = effective_reviewer_id(reviewer)
      topic.teams.reject do |team|
        team.participants.include?(reviewer) ||
          ReviewResponseMap.exists?(reviewer_id: rid, reviewee_id: team.id,
                                    reviewed_object_id: @assignment.id) ||
          review_cap_reached?(team)
      end
    end

    def review_cap_reached?(team)
      max = @assignment.max_reviews_per_submission
      max && ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: @assignment.id).count >= max
    end
  end
end
