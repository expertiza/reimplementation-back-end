module ReviewMappingStrategies
  class BaseStrategy
    def initialize(assignment)
      @assignment = assignment
    end

    def each_review_pair
      raise NotImplementedError, 'Static strategies must implement each_pair'
    end

    def assign_one(reviewer)
      raise NotImplementedError, 'Dynamic strategies must implement assign_one'
    end

    private

    # Returns the id used to look up this reviewer's mappings in ReviewResponseMap.
    # When the assignment uses team-based reviews, the mapping is keyed on the team id
    # rather than the individual participant id; this method abstracts that distinction
    # so callers do not need to check the assignment configuration themselves.
    def effective_reviewer_id(reviewer)
      return reviewer.id unless @assignment.is_review_done_by_teams && reviewer.is_a?(AssignmentParticipant)

      reviewer.team&.id || reviewer.id
    end
  end
end
