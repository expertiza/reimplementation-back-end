FactoryBot.define do
  factory :update_participant do
    
  end

  factory :sign_up_topic do
    
  end

  factory :user do
    sequence(:name) { |_n| Faker::Name.name.to_s.delete(" \t\r\n").downcase }
    sequence(:email) { |_n| Faker::Internet.email.to_s }
    password { 'password' }
    sequence(:full_name) { |_n| "#{Faker::Name.name}#{Faker::Name.name}".downcase }
    role factory: :role
    institution factory: :institution
  end

  factory :role do
    name { Faker::Name.name }
  end

  factory :assignment do
    sequence(:name) { |n| "assignment#{n}" }
  end


  factory :invitation do
    from_user factory: :user
    to_user factory: :user
    assignment factory: :assignment
    reply_status { 'W' }
  end

  factory :institution, class: Institution do
    name {'North Carolina State University'}
  end

  if ActiveRecord::Base.connection.table_exists?(:roles)
    factory :role_of_instructor, class: Role do
      name { 'Instructor' }
      parent_id { nil }
    end
  end

  factory :instructor, class: Instructor do
    name {'instructor6'}
    role {Role.where(name: 'Instructor').first || association(:role_of_instructor)}
    parent_id {1}
    email {'instructor6@gmail.com'}
  end

  factory :course, class: Course do
    sequence(:name) { |n| "CSC517, test#{n}" }
    instructor { Instructor.first || association(:instructor) }
    directory_path {'csc517/test'}
    info {'Object-Oriented Languages and Systems'}
    private {true}
    institution { Institution.first || association(:institution) }
  end


  factory :participant, class: AssignmentParticipant do
    assignment { Assignment.first || association(:assignment) }
    association :user, factory: :student
    type { 'AssignmentParticipant' }
  end

  factory :course_participant, class: CourseParticipant do
    course { Course.first || association(:course) }
    association :user, factory: :student
    type { 'CourseParticipant' }
  end

  factory :student, class: User do
    # Zhewei: In order to keep students the same names (2065, 2066, 2064) before each example.
    sequence(:name) { |n| n = n % 3; "student206#{n + 4}" }
    role { Role.where(name: 'Student').first || association(:role_of_student) }
    password { 'password' }
    email { 'expertiza@mailinator.com' }
    parent_id { 1 }
    mru_directory_path { nil }
    email_on_review { true }
    email_on_submission { true }
    email_on_review_of_review { true }
    is_new_user { false }
    master_permission_granted { 0 }
    handle { 'handle' }
    copy_of_emails { false }
  end

end