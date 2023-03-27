class Response < ApplicationRecord
  include ScorableMixin
  include MailMixin
  include ReviewCommentMixin

  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  # Get a collection of all comments across all rounds of a review
  # as well as a count of the total number of comments. Returns the
  # above information both for totals and in a list per-round.
  def self.get_all_review_comments(assignment_id, reviewer_id)
    comments = ''
    counter = 0
    @comments_in_round = []
    @counter_in_round = []
    assignment = Assignment.find(assignment_id)
    question_ids = Question.get_all_questions_with_comments_available(assignment_id)

    # Since reviews can have multiple rounds we need to iterate over all of them
    # to build our response.
    ReviewResponseMap.where(reviewed_object_id: assignment_id, reviewer_id: reviewer_id).find_each do |response_map|
      (1..assignment.num_review_rounds + 1).each do |round|
        @comments_in_round[round] = ''
        @counter_in_round[round] = 0
        last_response_in_current_round = response_map.response.select { |r| r.round == round }.last
        next if last_response_in_current_round.nil?

        last_response_in_current_round.scores.each do |answer|
          comments += answer.comments if question_ids.include? answer.question_id
          @comments_in_round[round] += (answer.comments ||= '')
        end
        additional_comment = last_response_in_current_round.additional_comment
        comments += additional_comment
        counter += 1
        @comments_in_round[round] += additional_comment
        @counter_in_round[round] += 1
      end
    end
    [comments, counter, @comments_in_round, @counter_in_round]
  end
end
