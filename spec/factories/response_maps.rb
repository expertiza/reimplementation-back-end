FactoryBot.define do
  factory :response_map do
    reviewed_object_id { 1 }
    reviewer_id { 1 }
    reviewee_id { 1 }
    type { 'ResponseMap' }
  end

end
