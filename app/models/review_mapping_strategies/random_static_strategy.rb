require_relative 'base_strategy'

module ReviewMappingStrategies
  class RandomStaticStrategy < BaseStrategy
    # Yields (reviewer, team) pairs with random assignment
    def each_review_pair
    # shuffle so that the students can't predict who they will review
      reviewers = @assignment.participants.select(&:can_review?).shuffle
      teams = @assignment.teams.to_a.shuffle

      return enum_for(:each_review_pair) if reviewers.empty? || teams.empty?

        # Example usage:
        # 1) With a block: iterate directly
        # strategy.each_review_pair { |reviewer, team| puts "#{reviewer.name} -> #{team.name}" }

        # 2) Without a block: get Enumerator first, then iterate
        # enum = strategy.each_review_pair
        # enum.each { |reviewer, team| ... }
      if block_given?
        teams.each do |team|
          reviewer = reviewers.sample
          yield reviewer, team
        end
      else
        enum_for(:each_review_pair)
      end
    end
  end
end