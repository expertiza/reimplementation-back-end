class AssignmentSurveyResponseMap < SurveyResponseMap
    belongs_to :assignment, foreign_key: 'reviewed_object_id'
    def questionnaire
        Questionnaire.find_by(id: reviewed_object_id)
    end
    
    def survey_parent
        assignment
    end
end