FactoryBot.define do
  factory :project_topic do
    sequence(:topic_name) { |n| "Topic #{n}" }
    sequence(:topic_identifier) { |n| "T#{n}" }
    max_choosers { 2 }
    category { "General" }
    association :assignment
  end
end