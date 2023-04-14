FactoryBot.define do
  factory :signed_up_team do
    id {1}
    preference_priority_number {1}
    association :signup_topic
    association :team
  end
end 