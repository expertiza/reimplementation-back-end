FactoryBot.define do
  factory :review_response_map do
    association :assignment
    reviewer { association :assignment_participant, assignment: assignment }
    reviewee { association :assignment_team, assignment: assignment }
    reviewed_object_id { assignment.id }

    trait :for_calibration do
      for_calibration { true }
    end
  end
end
