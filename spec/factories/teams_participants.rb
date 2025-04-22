# spec/factories/teams_participants.rb
FactoryBot.define do
  factory :teams_participant do
    association :participant
    association :team

    trait :with_user do
      after(:build) do |tp|
        tp.participant.user ||= build(:user)
      end
    end
  end
end
