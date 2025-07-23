
class FeedbackResponseMap < ResponseMap 
    belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'

    def assignment 
        review.map.assignment
    end 

    def questionnaire 
        Questionnaire.find_by(id: reviewed_object_id)
    end 

    def get_title 
        FEEDBACK_RESPONSE_MAP_TITLE
    end
end

