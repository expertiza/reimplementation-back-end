FactoryBot.define do
  factory :review_map do
    association :assignment
    association :reviewer, factory: :user
    association :reviewee, factory: :user
    reviewed_object { association(:submission, assignment: assignment) }
    type { 'ReviewResponseMap' }
    sequence(:reviewed_object_id) { |n| n }
    sequence(:reviewer_id) { |n| n }
    sequence(:reviewee_id) { |n| n + 1 }
  end
end



