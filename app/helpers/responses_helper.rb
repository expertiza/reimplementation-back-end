module ResponsesHelper
    def questionnaire_from_response_map(map, contributor, assignment)
        if ['ReviewResponseMap', 'SelfReviewResponseMap'].include?(map.type)
            get_questionnaire_by_contributor(map, contributor, assignment)
        else
            get_questionnaire_by_duty(map, assignment)
        end
    end
    def get_questionnaire_by_contributor(map, contributor, assignment)
        reviewees_topic = SignedUpTeam.topic_id_by_team_id(@contributor.id)
        @current_round = @assignment.number_of_current_round(reviewees_topic)
        @questionnaire = @map.questionnaire(@current_round, reviewees_topic)
    end
    def get_questionnaire_by_duty(map, assignment)
        if @assignment.duty_based_assignment?
            # E2147 : gets questionnaire of a particular duty in that assignment rather than generic questionnaire
            @questionnaire = @map.questionnaire_by_duty(@map.reviewee.duty_id)
        else
            @questionnaire = @map.questionnaire
        end
    end
end