module ReviewAggregator
  extend ActiveSupport::Concern

  # Generic method to compute average review grade from a collection of response maps
  def compute_average_review_score(maps)
    return nil if maps.blank?

    total_score = 0.0
    total_reviewers = 0

    maps.each do |map|
      score = map.aggregate_reviewers_score
      next if score.nil?

      total_score += score
      total_reviewers += 1
    end

    return nil if total_reviewers.zero?
    ((total_score / total_reviewers) * 100).round(2)
  end
end