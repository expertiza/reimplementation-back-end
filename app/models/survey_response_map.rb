# frozen_string_literal: true

# Intermediary model in the ResponseMap hierarchy. Has subclasses of:
#   AssignmentSurveyResponseMap
#   CourseSurveyResponseMap
#   GlobalSurveyResponseMap
# Includes only code shared between all subclasses
class SurveyResponseMap < ResponseMap
    belongs_to :survey_deployment, foreign_key: 'reviewee_id'
    belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id'

    def survey?
        true
    end

    def contributor
        nil
    end
end