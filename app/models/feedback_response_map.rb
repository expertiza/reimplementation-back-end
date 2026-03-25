# frozen_string_literal: true
class FeedbackResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'

  def assignment 
    review.map.assignment
  end 

  def questionnaire 
    Questionnaire.find_by(id: reviewed_object_id)
  end 

  def get_title 
    FEEDBACK_RESPONSE_MAP_TITLE
  end

  def questionnaire_type
    'AuthorFeedback'
  end

  # Returns the original contributor (the author who received the review)
  def contributor
    self.reviewee
  end

  # Sends feedback email notification for submitted feedback responses.
  # Failures are logged and swallowed so submission flow is not interrupted.
  # @param _response [Response, nil] recently submitted response (unused for now)
  def send_notification_email(_response = nil)
    return unless assignment.present?

    FeedbackEmailMailer.new(self, assignment).call
  rescue StandardError => e
    Rails.logger.error "FeedbackEmail failed for FeedbackResponseMap ##{id}: #{e.message}"
  end

  # Build a new instance from controller params (keeps creation details centralized)
  def self.build_from_params(params)
    new(params)
  end
end
