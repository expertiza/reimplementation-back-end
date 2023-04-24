# frozen_string_literal: true

class Response < ApplicationRecord
  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false

  def significant_difference?
    map_class = map.class
    existing_responses = map_class.assessments_for(map.reviewee)

    count = 0
    total = 0
    existing_responses.each do |response|
      unless id == response.id # the current_response is also in existing_responses array
        count += 1
        total +=  response.aggregate_questionnaire_score.to_f / response.maximum_score
      end
    end
    average_score = total / count

    # if this response is the first on this artifact, there's no grade conflict
    return false if count.zero?

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

end
