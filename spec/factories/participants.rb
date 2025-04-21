FactoryBot.define do
  factory :participant do
    association :user
    association :assignment, factory: :assignment
  end
end 