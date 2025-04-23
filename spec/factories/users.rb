FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    full_name { "Test User" }
    association :role
    association :institution
  end
end 