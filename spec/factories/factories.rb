FactoryBot.define do

  # Factory used for User objects
  factory :student, class: User do
    sequence(:name) { |n| n = n % 3; "student206#{n + 4}" }
    role { Role.where(name: 'Student').first || association(:role_of_student) }
    sequence(:fullname) { |n| n = n % 3; "206#{n + 4}, student" }
    # handle 'handle'
  end

  # Factory Used for TeamsParticipant Objects
  factory :teams_participant, class: TeamsParticipant do
    team { AssignmentTeam.first || association(:assignment_team) }
    # Beware: it is fragile to assume that role_id of student is 2 (or any other unchanging value)
    user { User.where(role_id: 2).first || association(:student) }
  end

  # Factory Used for Participant Objects
  factory :participant, class: Participant do
    handle {"handle"}
  end

  # Factory Used for Role Objects
  factory :role_of_student, class: Role do
  end

  # Factpry used for AssignmentParticipant Objects
  factory :assignment_participant, class: AssignmentParticipant do
    sequence(:name) { |n| "team#{n}" }
  end

  # Factory Used for SignUpTopic Objects
  factory :topic, class: SignUpTopic do
    topic_name { "Hello world!" }
  end

  # Factory Used for Assignment Objects
  factory :assignment, class: Assignment do
    # Help multiple factory-created assignments get unique names
    # Let the first created assignment have the name 'final2' to avoid breaking some fragile existing tests
    name { (Assignment.last ? ('assignment' + (Assignment.last.id + 1).to_s) : 'final2').to_s }
  end
end