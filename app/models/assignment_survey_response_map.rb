# frozen_string_literal: true

class AssignmentSurveyResponseMap < SurveyResponseMap
    include ExpertizaConstants::ResponseMapTitles
    belongs_to :assignment, foreign_key: 'reviewed_object_id'
    def survey_parent
        assignment
    end

    def get_title
        ASSIGNMENT_SURVEY_RESPONSE_MAP_TITLE
    end
end
