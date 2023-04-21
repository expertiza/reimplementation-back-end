# frozen_string_literal: true

class Response < ApplicationRecord

  def significant_difference?
    map_class = map.class
    existing_responses = map_class.assessments_for(map.reviewee)
    average_score_on_same_artifact_from_others, count = Response.avg_scores_and_count_for_prev_reviews(existing_responses, self)
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
    (average_score_on_same_artifact_from_others - score).abs * 100 > allowed_difference_percentage
  end

end
