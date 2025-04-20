# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  validates :map_id, presence: true

  after_save :handle_response_submission

  def submit
    update(is_submitted: true)
  end

  def handle_response_submission
    return unless is_submitted_changed? && is_submitted?
    
    # Send email notification through the response map
    send_notification_email
  end

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

  def aggregate_questionnaire_score
    scores.joins(:question)
          .where(questions: { scorable: true })
          .sum('answers.answer * questions.weight')
  end

  def maximum_score
    return 0 if scores.empty?
    
    questionnaire = questionnaire_by_answer(scores.first)
    questionnaire.max_question_score * active_scored_questions.size
  end

  private

  def send_notification_email
    return unless map.assignment.present?
    
    if map.is_a?(FeedbackResponseMap)
      FeedbackEmailService.new(map, map.assignment).call
    end
    # Add other response map type email services as needed
  end

  def active_scored_questions
    return [] if scores.empty?
    
    questionnaire = questionnaire_by_answer(scores.first)
    questionnaire.items.select(&:scorable?)
  end

  def questionnaire_by_answer(answer)
    answer&.question&.questionnaire
  end
end
