FactoryBot.define do
  factory :teams_user do
    association :user
    association :team
  end
end 