class AssignmentSurveyResponseMap < SurveyResponseMap
    belongs_to :assignment, foreign_key: 'reviewed_object_id'
    def survey_parent
        assignment
    end
end