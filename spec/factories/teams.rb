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
    end

    after(:build) do |team, evaluator|
      if team.assignment.nil?
        team.course = evaluator.course
      else
        team.course = team.assignment.course
      end
    end

    trait :with_assignment do
      after(:build) do |team, evaluator|
        team.assignment = create(:assignment, course: evaluator.course)
        team.course = team.assignment.course
      end
    end
  end

  factory :mentored_team, class: 'MentoredTeam' do
    name { Faker::Team.name }
    type { 'MentoredTeam' }

    transient do
      course { create(:course) }
    end

    assignment { create(:assignment, course: course) }

    # after(:build) do |team, evaluator|
    #   mentor_role = create(:role, :mentor)
    #   mentor = create(:user, role: mentor_role)
    #   team.mentor = mentor
    # end
  end

  factory :teams_participant, class: 'TeamsParticipant' do
    team
    participant
    user { participant.user }
  end

end 
