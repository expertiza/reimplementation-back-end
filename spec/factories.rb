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
    name { (Assignment.last ? "assignment#{Assignment.last.id + 1}" : 'final2').to_s }
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
    fullname {'6, instructor'}
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

  factory :teams_assignment do
    name { "Sample Team Assignment" }
    parent_id { 1 } # You can adjust this value as needed
    type { "Assignment" }
    comments_for_advertisement { "Sample comments for advertisement" }
    advertise_for_partner { true }
    submitted_hyperlinks { "Sample hyperlinks" }
    directory_num { 1 }
    grade_for_submission { 100 }
    comment_for_submission { "Sample comment for submission" }
    pair_programming_request { 1 }
  end
  
end
