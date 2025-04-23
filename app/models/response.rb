# Represents a response given by a reviewer in the peer review system
# Contains the actual feedback content and manages the response lifecycle
class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  # Associations
  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  # Convenience alias for response_map
  alias map response_map
  # Delegate common methods to response_map for easier access
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  validates :map_id, presence: true

  # Callback to handle any post-submission actions
  after_save :handle_response_submission

  # Marks the response as submitted
  # @return [Boolean] success of the submission update
  def submit
    update(is_submitted: true)
  end

  # Handles any necessary actions after a response is submitted
  # Currently focuses on email notifications
  # Only triggers when is_submitted changes from false to true
  def handle_response_submission
    return unless is_submitted_changed? && is_submitted?
    
    # Send email notification through the response map
    send_notification_email
  end

  # Checks if this response's score differs significantly from others
  # Used to flag potentially problematic or outlier reviews
  # @return [Boolean] true if the difference is reportable
  def reportable_difference?
    map_class = map.class
    existing_responses = map_class.assessments_for(map.reviewee)
    count = 0
    total = 0

    existing_responses.each do |response|
      next if id == response.id
      count += 1
      total += response.aggregate_questionnaire_score.to_f / response.maximum_score
    end

    return false if count.zero?

    average_score = total / count
    score = aggregate_questionnaire_score.to_f / maximum_score
    questionnaire = questionnaire_by_answer(scores.first)
    assignment = map.assignment

    assignment_questionnaire = AssignmentQuestionnaire.find_by(
      assignment_id: assignment.id,
      questionnaire_id: questionnaire.id
    )

    difference_threshold = assignment_questionnaire.try(:notification_limit) || 0.0
    (score - average_score).abs * 100 > difference_threshold
  end

  # Calculates the total score for all answers in this response
  # @return [Float] the aggregate score across all questions
  def aggregate_questionnaire_score
    scores.joins(:question)
          .where(questions: { scorable: true })
          .sum('answers.answer * questions.weight')
  end

  # Calculates the maximum possible score for this response
  # Based on the questionnaire's maximum question score and number of questions
  # @return [Integer] the maximum possible score
  def maximum_score
    return 0 if scores.empty?
    
    questionnaire = questionnaire_by_answer(scores.first)
    questionnaire.max_question_score * active_scored_questions.size
  end

  private

  # Sends notification emails when appropriate
  # Currently handles feedback response notifications
  def send_notification_email
    return unless map.assignment.present?
    
    if map.is_a?(FeedbackResponseMap)
      FeedbackEmailService.new(map, map.assignment).call
    end
    # Add other response map type email services as needed
  end

  # Gets all active questions that can be scored
  # @return [Array<Question>] list of active scored questions
  def active_scored_questions
    return [] if scores.empty?
    
    questionnaire = questionnaire_by_answer(scores.first)
    questionnaire.items.select(&:scorable?)
  end

  # Retrieves the questionnaire associated with an answer
  # @param answer [Answer] the answer to find the questionnaire for
  # @return [Questionnaire] the associated questionnaire
  def questionnaire_by_answer(answer)
    answer&.question&.questionnaire
  end
end
