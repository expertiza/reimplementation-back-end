# frozen_string_literal: true
class FeedbackResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
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

  # Returns the reviewer who gave the original review
  def reviewer
    self.reviewer
  end

  # Accepts a report visitor for double-dispatch report generation.
  def self.accept_report_visitor(visitor, assignment_id)
    visitor.visit_feedback_response_map(assignment_id)
  end

  def send_feedback_email(assignment)
    FeedbackEmailMailer.new(self, assignment).call
  end

  # Build a new instance from controller params (keeps creation details centralized)
  def self.build_from_params(params)
    new(params)
  end
end
