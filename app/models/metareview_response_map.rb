class MetareviewResponseMap < ResponseMap
    belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
    belongs_to :review_mapping, class_name: 'ResponseMap', foreign_key: 'reviewed_object_id'
    delegate :assignment, to: :reviewee
  
end
  