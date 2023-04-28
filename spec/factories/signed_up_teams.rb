FactoryBot.define do
  factory :signed_up_team do
    
    initialize_with {SignedUpTeam.send(:create, signup_topic["id"], team["id"])}

    preference_priority_number {1}
    association :signup_topic
    association :team
  end
end 