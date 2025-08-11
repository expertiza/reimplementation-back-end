class TeammateReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id'

  def questionnaire_type
      'TeammateReview'
  end

  def questionnaire
    assignment.questionnaires.find_by(type: 'TeammateReviewQuestionnaire')
  end

  def questionnaire_by_duty(duty_id)
    duty_questionnaire = assignment.questionnaires.find(assignment_id: assignment.assignment_id, duty_id: duty_id).first
    if duty_questionnaire.nil?
      questionnaire
    else
      duty_questionnaire
    end
  end

  def get_reviewer
    AssignmentParticipant.find(reviewer_id)
  end

  def self.teammate_response_report(id)
    TeammateReviewResponseMap.select('DISTINCT reviewer_id').where('reviewed_object_id = ?', id)
  end
end