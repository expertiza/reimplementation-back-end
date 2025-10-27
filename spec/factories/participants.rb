# frozen_string_literal: true

FactoryBot.define do
  factory :assignment_participant, class: 'AssignmentParticipant' do
    type { 'AssignmentParticipant' }
    association :user
    association :assignment
    parent_id { assignment.id }
    handle { user.name }

    # Trait to make this participant a mentor
    trait :with_mentor_duty do
      # We move all logic into the `after(:build)` block
      # to ensure we have access to the participant's assignment.

      after(:build) do |participant, evaluator|
        # 1. Find or create the duty, now WITH the required instructor
        mentor_duty = Duty.find_or_create_by!(
          name: 'mentor',
          instructor: participant.assignment.instructor
        )

        # 2. Assign the duty to the participant
        participant.duty = mentor_duty

        # 3. Ensure the duty is associated with the assignment
        unless participant.assignment.duties.include?(mentor_duty)
          participant.assignment.duties << mentor_duty
        end
      end
    end
  end

  factory :course_participant, class: 'CourseParticipant' do
    type { 'CourseParticipant' }
    association :user
    association :course
    parent_id { course.id }
    handle { user.name }
  end
end
