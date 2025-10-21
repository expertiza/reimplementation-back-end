require_relative 'base_strategy'

module ReviewMappingStrategies
  class LeastReviewedTopicStrategy < BaseStrategy
    # Assign reviewer to a team in a topic where review counts
    # are within k fairness threshold
    def assign_one(reviewer, k: 1)
      counts = ReviewResponseMap.where(reviewed_object_id: @assignment.id)
                                .joins(reviewee: :topic)
                                .group('topics.id')
                                .count

      min_count = counts.values.min || 0

      # Eligible topics within threshold
      eligible_topics = counts.select { |_topic_id, count| count <= min_count + k }.keys

      # Choose the first eligible topic deterministically
      topic_id = eligible_topics.first
      topic    = SignUpTopic.find(topic_id)

      # From this topic, pick a valid team
      team = teams_eligible_for_review(reviewer, topic).min_by do |t|
        counts[t.id] || 0
      end

      team
    end

    private

    # Only allow teams in the topic that are valid for this reviewer
    def teams_eligible_for_review(reviewer, topic)
      topic.assignment_teams.reject do |team|
        (team.participants.include?(reviewer)) ||
        ReviewResponseMap.exists?(
          reviewer_id: reviewer.id,
          reviewee_id: team.id,
          reviewed_object_id: @assignment.id
        )
      end
    end
  end
end
