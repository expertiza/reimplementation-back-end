class TeammateReviewResponseMap < ResponseMap
    belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false

    def questionnaire_type
        'TeammateReview'
    end
end