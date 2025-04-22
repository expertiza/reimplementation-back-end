# spec/factories/participants.rb
FactoryBot.define do
  factory :participant do
    association :user
    association :assignment

    trait :with_team do
      association :team
    end

    trait :for_course do
      after(:build) do |participant|
        participant.assignment = create(:assignment, :with_course)
      end
    end
  end
end
