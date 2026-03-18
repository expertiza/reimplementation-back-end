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
  end
end
