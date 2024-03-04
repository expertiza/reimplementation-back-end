class ResponseService
  include Scoring

  # sorts the questions passed by sequence number in ascending order
  def sort_questions(questions)
    questions.sort_by(&:seq)
  end
  # checks if the questionnaire is nil and opens drop down or rating accordingly
  def set_dropdown_or_scale(response_dto)
    use_dropdown = AssignmentQuestionnaire.where(assignment_id: response_dto.assignment.try(:id),
                                                 questionnaire_id: response_dto.questionnaire.try(:id))
                                          .first.try(:dropdown)
    dropdown_or_scale = (use_dropdown ? 'dropdown' : 'scale')
    return dropdown_or_scale
  end

  # This method is called within set_content and when the new_response flag is set to true
  # Depending on what type of response map corresponds to this response, the method gets the reference to the proper questionnaire
  # This is called after assign_instance_vars in the new method
  def questionnaire_from_response_map(response_dto)
    case response_dto.map.type
    when 'ReviewResponseMap', 'SelfReviewResponseMap'
      reviewees_topic = SignedUpTeam.topic_id_by_team_id(response_dto.contributor.id)
      response_dto.current_round = response_dto.assignment.number_of_current_round(reviewees_topic)
      response_dto.questionnaire = response_dto.map.questionnaire(response_dto.current_round, reviewees_topic)
    when
    'MetareviewResponseMap',
      'TeammateReviewResponseMap',
      'FeedbackResponseMap',
      'CourseSurveyResponseMap',
      'AssignmentSurveyResponseMap',
      'GlobalSurveyResponseMap',
      'BookmarkRatingResponseMap'
      if response_dto.assignment.duty_based_assignment?
        # E2147 : gets questionnaire of a particular duty in that assignment rather than generic questionnaire
        response_dto.questionnaire = response_dto.map.questionnaire_by_duty(response_dto.map.reviewee.duty_id)
      else
        response_dto.questionnaire = response_dto.map.questionnaire
      end
    end
  end

  # This method is called within set_content when the new_response flag is set to False
  # This method gets the questionnaire directly from the response object since it is available.
  def questionnaire_from_response(response_dto)
    # if user is not filling a new rubric, the response_dtoresponse object should be available.
    # we can find the questionnaire from the question_id in answers
    answer = response_dto.response.scores.first
    response_dto.questionnaire = response_dto.response.questionnaire_by_answer(answer)
  end
  def score(params)
    Class.new.extend(Scoring).assessment_score(params)
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