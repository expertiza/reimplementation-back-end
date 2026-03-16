FactoryBot.define do
  factory :review_response_map do
    association :assignment
    association :reviewer, factory: :user
    association :reviewee, factory: :team
    reviewed_object_id { 1 }
  end
end