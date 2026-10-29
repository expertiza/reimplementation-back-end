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

    # Returns the id to use when querying ReviewResponseMap for this reviewer:
    # the reviewer's team id when reviews are done by teams, otherwise their own id.
    def effective_reviewer_id(reviewer)
      return reviewer.id unless @assignment.is_review_done_by_teams && reviewer.is_a?(AssignmentParticipant)

      reviewer.team&.id || reviewer.id
    end
  end
end
