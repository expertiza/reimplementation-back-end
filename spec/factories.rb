FactoryBot.define do
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
    sequence(:name) { |n| "Assignment #{Time.now.to_f}_#{n}" }
    directory_path { "/path/to/assignment_files" }
    course
    instructor { course.instructor }
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
    # create unique names with no numbers
    sequence(:name) { |n| "instructor#{Faker::Alphanumeric.alpha(number: 4).downcase}" }
    password { 'password123' }
    email { 'instructor6@gmail.com' }
    role_id { 3 }
    full_name { 'Instructor Six' }

    # Ensure a role exists and associate it
    after(:build) do |instructor|
      instructor_role = Role.find_or_create_by!(name: 'Instructor', id: 3)
      instructor.role = instructor_role
      instructor.role_id = instructor_role.id
    end
  end


  factory :student, class: User do
    sequence(:name) { |n| "student#{Faker::Alphanumeric.alpha(number: 4).downcase}" }
    full_name { Faker::Name.name }
    password { 'password123' }
    email {'studenttest@gmail.com'}

    after(:build) do |user|
      student_role = Role.find_or_create_by!(name: 'Student', id: 5)
      user.role = student_role
    end
  end

  factory :course, class: Course do
    sequence(:name) { |n| "CSC517, test#{n}" }
    instructor { create(:instructor) }
    directory_path {'csc517/test'}
    info {'Object-Oriented Languages and Systems'}
    private {true}
    institution { Institution.first || association(:institution) }
  end

  factory :response_map do
    reviewee_id { create(:student).id }
    reviewed_object_id { create(:questionnaire).id }
  end

  factory :participant do
    user { create(:student) }
    assignment { create(:assignment) }
  end

end
