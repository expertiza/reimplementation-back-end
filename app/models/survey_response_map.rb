# Intermediary model in the ResponseMap hierarchy. Has subclasses of:
#   AssignmentSurveyResponseMap
#   CourseSurveyResponseMap
#   GlobalSurveyResponseMap

class SurveyResponseMap < ResponseMap
    def survey?
        true
    end
end