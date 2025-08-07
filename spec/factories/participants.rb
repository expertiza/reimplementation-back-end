FactoryBot.define do
  factory :participant do
    association :user
    association :assignment, factory: :assignment
  end
  
  factory :assignment_participant, class: 'AssignmentParticipant' do
    association :user
    association :assignment, factory: :assignment
    parent_id { assignment.id }
    handle { user.name }
  end

  factory :course_participant, class: 'CourseParticipant' do
    association :user
    association :course, factory: :course
    parent_id { course.id }
    handle { user.name }
  end
end 
