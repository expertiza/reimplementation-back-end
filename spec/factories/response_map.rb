FactoryBot.define do
  factory :response_map do
    association :reviewer, factory: :participant
    # Other required associations or attributes
  end
end