# frozen_string_literal: true

module MetricHelper
  # Determine the average size of review comments in each round
  # the first entry in the returned list is the overall average
  # word count.

  def volume_of_review_comments(reviewer_id)
    comments_in_round, counter_in_round = get_all_review_comments(reviewer_id)
    num_rounds = comments_in_round.count - 1 # ignore nil element (index 0)

    comments = ''
    comment_count = 0
    comments_in_round.each { |comment| comments += comment unless comment.nil? }
    counter_in_round.each { |count| comment_count += count unless count.nil? }

    overall_avg_vol = (Lingua::EN::Readability.new(comments).num_words / (comment_count.zero? ? 1 : comment_count)).round(0)
    review_comments_volume = []
    review_comments_volume.push(overall_avg_vol)
    (1..num_rounds).each do |round|
      num = Lingua::EN::Readability.new(comments_in_round[round]).num_words
      den = (counter_in_round[round].zero? ? 1 : counter_in_round[round])
      avg_vol_in_round = (num / den).round(0)
      review_comments_volume.push(avg_vol_in_round)
    end
    review_comments_volume
  end

  # Get a collection of all comments across all rounds of a review
  # as well as a count of the total number of comments. Returns the
  # above information both for totals and in a list per-round.
  def get_all_review_comments(reviewer_id)
    comments_in_round = []
    counter_in_round = []

    ReviewResponseMap.where(reviewed_object_id: id, reviewer_id:).find_each do |response_map|
      (1..num_review_rounds + 1).each do |round|
        comments_in_round[round] = ''
        counter_in_round[round] = 0
        last_response_in_current_round = response_map.response.select { |r| r.round == round }.last
        next if last_response_in_current_round.nil?

        last_response_in_current_round.scores.each do |answer|
          comments_in_round[round] += (answer.comments ||= '')
        end
        additional_comment = last_response_in_current_round.additional_comment
        comments_in_round[round] += additional_comment
        counter_in_round[round] += 1
      end
    end
    [comments_in_round, counter_in_round]
  end
end
