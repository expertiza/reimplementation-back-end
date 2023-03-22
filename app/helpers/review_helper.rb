# frozen_string_literal: true

module ReviewHelper

  def self.volume_of_review_comments(assignment_id, reviewer_id)
    comments, counter,
      @comments_in_round, @counter_in_round = Response.concatenate_all_review_comments(assignment_id, reviewer_id)
    num_rounds = @comments_in_round.count - 1 # ignore nil element (index 0)

    overall_avg_vol = (Lingua::EN::Readability.new(comments).num_words / (counter.zero? ? 1 : counter)).round(0)
    review_comments_volume = []
    review_comments_volume.push(overall_avg_vol)
    (1..num_rounds).each do |round|
      num = Lingua::EN::Readability.new(@comments_in_round[round]).num_words
      den = (@counter_in_round[round].zero? ? 1 : @counter_in_round[round])
      avg_vol_in_round = (num / den).round(0)
      review_comments_volume.push(avg_vol_in_round)
    end
    review_comments_volume
  end
end
