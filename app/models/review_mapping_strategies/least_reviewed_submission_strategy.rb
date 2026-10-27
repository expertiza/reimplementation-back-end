require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedSubmissionStrategy < BaseStrategy
    # Returns the team with the fewest reviews so far,
    # skipping self-review and duplicate assignments.
    # Uses review_topic_threshold as a tolerance window so all teams within
    # min_count + threshold are eligible (matching old reject_by_least_reviewed).
    def assign_one(reviewer)
      counts = ReviewResponseMap.where(reviewed_object_id: @assignment.id)
                                .group(:reviewee_id)
                                .count

      eligible_teams = teams_eligible_for_review(reviewer)
      return nil if eligible_teams.empty?

      threshold = @assignment.review_topic_threshold || 0
      min_count = eligible_teams.map { |t| counts[t.id] || 0 }.min
      window    = eligible_teams.select { |t| (counts[t.id] || 0) <= min_count + threshold }
      window.min_by { |t| counts[t.id] || 0 }
    end

    private

    # Excludes reviewer's own team, already-reviewed teams, teams with no
    # submissions, and teams that have reached max_reviews_per_submission.
    def teams_eligible_for_review(reviewer)
      rid = effective_reviewer_id(reviewer)
      @assignment.teams.select(&:has_submissions?).reject do |team|
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
