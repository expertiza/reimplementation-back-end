FactoryBot.define do
  factory :response_map do
    sequence(:reviewed_object_id)
    sequence(:reviewer_id)
    sequence(:reviewee_id)
    type { 'ReviewResponseMap' } # Replace "SomeType" with a default value appropriate for your model
    calibrate_to { false }
    team_reviewing_enabled { false }
    assignment_questionnaire_id { 1 }
  end
end
