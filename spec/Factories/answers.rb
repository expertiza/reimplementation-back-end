FactoryBot.define do
  factory :answer do
    association :question
    association :response
    answer { Faker::Lorem.sentence }
    comments { Faker::Lorem.paragraph }
  end
end