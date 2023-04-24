class TeammateReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id'

  # get the questionaries associated with this instance of the teammate response map
  # the response map belongs to an assignment hence this is a convenience function for getting the questionaires
  def questionnaire
    assignment.questionnaires.find_by(type: 'TeammateReviewQuestionnaire')
  end

  # gets questionnaire for a particular duty. If no questionnaire is found for the given duty, returns the
  # default questionnaire set for TeammateReviewQuestionnaire type.
  # @param duty_id the the duty_id associated with the Assignment questionaire
  def questionnaire_by_duty(duty_id)
    duty_questionnaire = AssignmentQuestionnaire.where(assignment_id: assignment.id, duty_id: duty_id).first
    if duty_questionnaire.nil?
      questionnaire
    else
      Questionnaire.find(duty_questionnaire.questionnaire_id)
    end
  end

  # overloaded method, which does have any business logic implementation
  # @return nil
  def contributor
    nil
  end

  # getter for title. All response map types have a unique title
  def title
    'Teammate Review'
  end

  # get the reviewer associated with this response map instance
  # @return AssignmentParticipant instance
  def reviewer
    AssignmentParticipant.find(reviewer_id)
  end

  # get a teammate response report a given review object. This provides ability to see all teammate response for a review
  # @param id is the review object id
  def self.teammate_response_report(id)
    select('DISTINCT reviewer_id').where('reviewed_object_id = ?', id)
  end

  # Send emails for review response
  # @param email_command is a command object which will be fully hydrated in this function an dpassed to the mailer service
  # command should be initialized to a nested hash which invoking this function {body: {}}
  # @param assignment is the assignment instance for which the email is related to
  def send_email(command, assignment)
    mail = TeammateReviewEmailSendingMethod.new(command, assignment, reviewee_id)

    mail.accept(TeammateReviewEmailVisitor.new)
  end
end
