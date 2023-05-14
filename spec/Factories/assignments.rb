FactoryBot.define do
  factory :assignment do
    association :course
    sequence(:name) { |n| "assignment-#{n}" }
    max_team_size { 4 }
  end
end
