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

    def effective_reviewer_id(reviewer)
      return reviewer.id unless @assignment.is_review_done_by_teams && reviewer.is_a?(AssignmentParticipant)

      reviewer.team&.id || reviewer.id
    end
  end
end
