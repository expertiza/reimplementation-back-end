# frozen_string_literal: true

FactoryBot.define do
  factory :assignment_questionnaire do
    association :assignment
    association :questionnaire
    used_in_round { nil }
    notification_limit { 15 }
    questionnaire_weight { 100 }
    topic_id { nil }
  end
end
