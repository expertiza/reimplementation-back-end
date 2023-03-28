FactoryBot.define do
  factory :user do
    name {"user"}
    crypted_password {'1111111111111111111111111111111111111111'}
    role_id {0}
  end
  factory :response do
    map_id {0}
  end

  factory :review_response_map do
    assignment { Assignment.first || association(:assignment) }
    reviewer { AssignmentParticipant.first || association(:participant) }
    reviewee { AssignmentTeam.first || association(:assignment_team) }
    type { 'ReviewResponseMap' }
    calibrate_to { 0 }
  end
end