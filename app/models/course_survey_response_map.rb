class CourseSurveyResponseMap < SurveyResponseMap
    belongs_to :course, foreign_key: 'reviewed_object_id'
    
    def questionnaire
        Questionnaire.find_by(id: survey_deployment.questionnaire_id)
    end
    
    def survey_parent
        course
    end

    def get_title
        COURSE_SURVEY_RESPONSE_MAP_TITLE
    end
end