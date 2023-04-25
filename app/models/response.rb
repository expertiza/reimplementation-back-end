# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

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

  def significant_difference?
    map_class = map.class
    # gets all responses made by a reviewee
    existing_responses = map_class.assessments_for(map.reviewee)

    count = 0
    total = 0
    # gets the sum total percentage scores of all responses that are not this response
    existing_responses.each do |response|
      unless id == response.id # the current_response is also in existing_responses array
        count += 1
        total +=  response.aggregate_questionnaire_score.to_f / response.maximum_score
      end
    end

    # if this response is the only response by the reviewee, there's no grade conflict
    return false if count.zero?

    # calculates the average score of all other responses
    average_score = total / count

    # This score has already skipped the unfilled scorable question(s)
    score = aggregate_questionnaire_score.to_f / maximum_score
    questionnaire = questionnaire_by_answer(scores.first)
    assignment = map.assignment
    assignment_questionnaire = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: questionnaire.id)

    # notification_limit can be specified on 'Rubrics' tab on assignment edit page.
    allowed_difference_percentage = assignment_questionnaire.notification_limit.to_f

    # the range of average_score_on_same_artifact_from_others and score is [0,1]
    # the range of allowed_difference_percentage is [0, 100]
    (average_score - score).abs * 100 > allowed_difference_percentage
  end

  def aggregate_questionnaire_score
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

  def questionnaire_by_answer(answer)
    if answer.nil?
      # there is small possibility that the answers is empty: when the questionnaire only have 1 question and it is a upload file question
      # the reason is that for this question type, there is no answer record, and this question is handled by a different form
      map = ResponseMap.find(map_id)
      # E-1973 either get the assignment from the participant or the map itself
      assignment = if map.is_a? ReviewResponseMap
                     map.assignment
                   else
                     Participant.find(map.reviewer_id).assignment
                   end
      questionnaire = Questionnaire.find(assignment.review_questionnaire_id)
    else # for all the cases except the case that  file submission is the only question in the rubric.
      questionnaire = Question.find(answer.question_id).questionnaire
    end
    questionnaire
  end

end
