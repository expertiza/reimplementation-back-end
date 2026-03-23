module ReviewMappingStrategies
  class ReviewMappingFactory
    def self.build(strategy_type, assignment, **options)
      case strategy_type.to_sym
      when :round_robin
        RoundRobinStrategy.new(assignment)
      when :random
        RandomStaticStrategy.new(assignment)
      when :fewest_reviews
        LeastReviewedSubmissionStrategy.new(assignment)
      when :topic_fairness
        LeastReviewedTopicStrategy.new(assignment)
      when :csv
        CsvImportStrategy.new(assignment, options[:csv_text])
      else
        raise ArgumentError, "Unknown strategy type: #{strategy_type}"
      end
    end
  end
end
