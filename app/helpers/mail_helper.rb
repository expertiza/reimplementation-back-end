# frozen_string_literal: true

module MailHelper

  # only two types of responses more should be added
  def email(partial = 'new_submission')
    message = {}
    message[:body] = {}
    message[:body][:partial_name] = partial
    response_map = ResponseMap.find map_id
    participant = Participant.find(response_map.reviewer_id)
    # parent is used as a common variable name for either an assignment or course depending on what the questionnaire is associated with
    parent = if response_map.survey?
               response_map.survey_parent
             else
               Assignment.find(participant.parent_id)
             end
    message[:subject] = 'A new submission is available for ' + parent.name
    response_map.email(message, participant, parent)
  end
end
