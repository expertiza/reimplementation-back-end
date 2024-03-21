FactoryBot.define do
  factory :answer do
    association :response
    sequence(:question_id) { |n| n }
    answer { 5 }
    comments { 'answer comments' }
  end
end
