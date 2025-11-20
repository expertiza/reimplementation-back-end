# frozen_string_literal: true
class FeedbackResponseMap < ResponseMap 
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy

    def questionnaire_type
      'AuthorFeedback'
    end

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
end