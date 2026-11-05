require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedSubmissionStrategy < BaseStrategy
    # Returns the team with the fewest submitted reviews so far,
    # skipping self-review and teams the reviewer has already been assigned to.
    # Uses review_topic_threshold as a tolerance window so all teams within
    # min_count + threshold submitted reviews are eligible.
    def assign_one(reviewer)
      eligible_teams = base_eligible_teams(reviewer)
      return nil if eligible_teams.empty?

      teams_in_review_window(base_eligible_teams(reviewer)).min_by { |t| submission_review_counts[t.id] || 0 }
    end

    private

    # Returns the number of submitted reviews per team for this assignment,
    # keyed by reviewee_id. Only counts mappings that have a submitted response.
    def submission_review_counts
      @submission_review_counts ||= ReviewResponseMap
                                    .where(reviewed_object_id: @assignment.id)
                                    .joins(:responses).where(responses: { is_submitted: true })
                                    .group(:reviewee_id)
                                    .count
    end

    # Second-pass filter: from the candidate teams, keeps only those whose submitted
    # review count is within the fairness window (≤ min_count + review_topic_threshold).
    # Teams that have already received more than min_count + threshold submitted reviews
    # are excluded so that review load stays balanced.
    def teams_in_review_window(base_teams)
      counts    = submission_review_counts
      threshold = @assignment.review_topic_threshold || 0
      min_count = base_teams.map { |t| counts[t.id] || 0 }.min
      base_teams.select { |t| (counts[t.id] || 0) <= min_count + threshold }
    end

    # First-pass filter: returns candidate teams that have submissions, are not the
    # reviewer's own team, have not already been assigned to this reviewer, and have
    # not reached the per-submission review cap. Teams that survive this filter are
    # then narrowed further by teams_in_review_window before being considered eligible.
    def base_eligible_teams(reviewer)
      rid = effective_reviewer_id(reviewer)
      @assignment.teams.select(&:has_submissions?).reject do |team|
        team.participants.include?(reviewer) ||
          ReviewResponseMap.exists?(reviewer_id: rid, reviewee_id: team.id,
                                    reviewed_object_id: @assignment.id) ||
          review_cap_reached?(team)
      end
    end

    # Returns true if the team has already received the maximum number of submitted reviews
    # allowed per submission (max_reviews_per_submission on the assignment).
    def review_cap_reached?(team)
      max = @assignment.max_reviews_per_submission
      max && ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: @assignment.id).count >= max
    end
  end
end
