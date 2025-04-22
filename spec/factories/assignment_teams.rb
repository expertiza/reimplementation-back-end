# Factory for creating AssignmentTeam test instances
# AssignmentTeam represents a team of students working on an assignment
FactoryBot.define do
  factory :assignment_team do
    # Generate a random team name using Faker
    name { Faker::Team.name }
    # Create an associated assignment for the team
    # This ensures each team is properly associated with an assignment
    association :assignment
  end
end 