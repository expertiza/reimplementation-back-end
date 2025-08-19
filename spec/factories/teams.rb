# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    name { Faker::Team.name }
    type { 'CourseTeam' }

    trait :with_assignment do
      association :assignment, factory: :assignment
    end
  end

  factory :course_team, class: 'CourseTeam' do
    name { Faker::Team.name }
    type { 'CourseTeam' }
    association :course, factory: :course
  end

  factory :assignment_team, class: 'AssignmentTeam' do
    name { Faker::Team.name }
    type { 'AssignmentTeam' }
    
    transient do
      course { create(:course) }
      max_size { 5 } # Now passed to the assignment, not the team
    end

    assignment do
      create(:assignment, course: course, max_team_size: max_size)
    end

    after(:build) do |team, evaluator|
      unless team.assignment.nil?
        team.assignment.update(max_team_size: evaluator.max_size) if evaluator.max_size
      end
    end

    trait :with_assignment do
      after(:build) do |team, evaluator|
        team.assignment ||= create(:assignment, course: evaluator.course, max_team_size: evaluator.max_size)
      end
    end
  end

  factory :mentored_team, class: 'MentoredTeam' do
    name { Faker::Team.name }
    type { 'MentoredTeam' }
    association :assignment, factory: :assignment

    after(:build) do |team, _evaluator|
      mentor_role = Role.find_by(name: 'Mentor') || create(:role, :mentor)
      mentor = create(:user, role: mentor_role)
      team.mentor ||= mentor
      team.parent_id ||= team.assignment.id
    end
  end

  factory :teams_participant, class: 'TeamsParticipant' do
    team
    participant
    user { participant.user }
  end
end
