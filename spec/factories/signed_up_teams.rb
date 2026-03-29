# frozen_string_literal: true

FactoryBot.define do
  factory :signed_up_team do
    association :project_topic
    association :team, factory: :assignment_team
    is_waitlisted { false }
  end
end
