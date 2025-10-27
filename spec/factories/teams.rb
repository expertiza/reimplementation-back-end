# frozen_string_literal: true

FactoryBot.define do
  # NOTE: The base :team factory has been removed.
  # Teams are an abstract class and should not be instantiated directly.
  # Please use :course_team, :assignment_team, or :mentored_team.

  factory :course_team, class: 'CourseTeam' do
    name { Faker::Team.name }
    association :course
  end

  factory :assignment_team, class: 'AssignmentTeam' do
    name { Faker::Team.name }

    # Allows passing max_size to the assignment, e.g.,
    # create(:assignment_team, max_size: 3)
    transient do
      max_size { 5 }
    end

    # Create the assignment and pass transient values to it
    association :assignment, factory: :assignment, max_team_size: nil

    # Use after(:build) to handle transient properties
    after(:build) do |team, evaluator|
      # This check ensures we don't override an explicitly passed assignment
      # just to set the max_team_size.
      if team.assignment&.persisted? && evaluator.max_size
        team.assignment.update_column(:max_team_size, evaluator.max_size)
      end
    end

    # Trait to automatically create a mentor duty for the assignment
    trait :with_mentor_duty do
      after(:create) do |team|
        duty = Duty.find_or_create_by!(
          name: 'mentor',
          instructor: team.assignment.instructor
        )
        team.assignment.duties << duty unless team.assignment.duties.include?(duty)
      end
    end
  end

  factory :mentored_team, parent: :assignment_team, class: 'MentoredTeam' do
    # This factory now inherits all the logic from :assignment_team,
    # including assignment creation, parent_id, and max_size transient.
    
    # By default, a mentored team factory should set up the mentor duty
    with_mentor_duty
  end
end
