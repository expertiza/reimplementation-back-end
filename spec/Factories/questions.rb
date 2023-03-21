FactoryBot.define do
  factory :question do
    association :assignment
    txt { Faker::Lorem.sentence }
  end
end