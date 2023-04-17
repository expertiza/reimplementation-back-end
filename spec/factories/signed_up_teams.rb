FactoryBot.define do
  factory :signed_up_team do
    preference_priority_number {1}
    association :signup_topic
    association :team
  end
end 