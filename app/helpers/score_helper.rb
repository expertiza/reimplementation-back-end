# frozen_string_literal: true

module ScoreHelper
  # Computes the total score awarded for a review
  def calculate_total_score
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    sum
  end

  # bug fixed
  # Returns the average score for this response as an integer (0-100)
  # def average_score
  #   if maximum_score.zero?
  #     'N/A'
  #   else
  #     ((aggregate_questionnaire_score.to_f / maximum_score.to_f) * 100).round
  #   end
  # end
  #
  # # Returns the maximum possible score for this response
  # def maximum_score
  #   # only count the scorable questions, only when the answer is not nil (we accept nil as
  #   # answer for scorable questions, and they will not be counted towards the total score)
  #   total_weight = 0
  #   scores.each do |s|
  #     question = Question.find(s.question_id)
  #     total_weight += question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
  #   end
  #   questionnaire = if scores.empty?
  #                     questionnaire_by_answer(nil)
  #                   else
  #                     questionnaire_by_answer(scores.first)
  #                   end
  #   total_weight * questionnaire.max_question_score
  # end
  #
  # # only two types of responses more should be added
  # def email(partial = 'new_submission')
  #   defn = {}
  #   defn[:body] = {}
  #   defn[:body][:partial_name] = partial
  #   response_map = ResponseMap.find map_id
  #   participant = Participant.find(response_map.reviewer_id)
  #   # parent is used as a common variable name for either an assignment or course depending on what the questionnaire is associated with
  #   parent = if response_map.survey?
  #              response_map.survey_parent
  #            else
  #              Assignment.find(participant.parent_id)
  #            end
  #   defn[:subject] = 'A new submission is available for ' + parent.name
  #   response_map.email(defn, participant, parent)
  # end
  #
  # def self.volume_of_review_comments(assignment_id, reviewer_id)
  #   comments, counter,
  #     @comments_in_round, @counter_in_round = Response.concatenate_all_review_comments(assignment_id, reviewer_id)
  #   num_rounds = @comments_in_round.count - 1 # ignore nil element (index 0)
  #
  #   overall_avg_vol = (Lingua::EN::Readability.new(comments).num_words / (counter.zero? ? 1 : counter)).round(0)
  #   review_comments_volume = []
  #   review_comments_volume.push(overall_avg_vol)
  #   (1..num_rounds).each do |round|
  #     num = Lingua::EN::Readability.new(@comments_in_round[round]).num_words
  #     den = (@counter_in_round[round].zero? ? 1 : @counter_in_round[round])
  #     avg_vol_in_round = (num / den).round(0)
  #     review_comments_volume.push(avg_vol_in_round)
  #   end
  #   review_comments_volume
  # end
end
