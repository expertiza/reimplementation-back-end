require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedSubmissionStrategy < BaseStrategy
    # Returns the team with the fewest reviews so far,
    # skipping self-review and duplicate assignments
    def assign_one(reviewer)
      counts = ReviewResponseMap.where(reviewed_object_id: @assignment.id)
                                .group(:reviewee_id)
                                .count

      eligible_teams = teams_eligible_for_review(reviewer)

      eligible_teams.min_by { |t| counts[t.id] || 0 }
    end

    private

    # Excludes the team reviewer is on aand the teams 
    # that the reviewer has already reviewed
    def teams_eligible_for_review(reviewer)
      @assignment.teams.reject do |team|
        
        (team.participants.include?(reviewer)) ||
        # Skip duplicate reviews
        ReviewResponseMap.exists?(
          reviewer_id: reviewer.id,
          reviewee_id: team.id,
          reviewed_object_id: @assignment.id
        )
      end
    end
  end
end
