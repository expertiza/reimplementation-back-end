require_relative 'base_strategy'

module ReviewMappingStrategies
  class RoundRobinStrategy < BaseStrategy
    # Yields (reviewer, reviewee team) pairs in round-robin order
    def each_review_pair
      reviewers = @assignment.participants.select(&:can_review?)
      teams = @assignment.teams.to_a

      return enum_for(:each_review_pair) if reviewers.empty? || teams.empty?
      reviewers_cycle = reviewers.cycle

      if block_given?
        teams.each { |team| yield reviewers_cycle.next, team }
      else
        enum_for(:each_review_pair)
      end
    end
  end
end
