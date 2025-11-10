FactoryBot.define do
  factory :submission do
    association :team
    association :assignment
    content { "Sample submission text" }
  end
end
