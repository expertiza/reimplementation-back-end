FactoryBot.define do
  factory :response do
    association :map
    association :reviewee, factory: :user
    association :reviewer, factory: :user
    is_submitted { true }
    round { 1 }
  end
end