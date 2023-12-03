
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "user#{n}".downcase }
    full_name { "test name" }
    email { "test@example.com" }
    password { "password123" } # Ensure it meets validation requirements
    association :role, factory: :role
    institution { nil } # If it's optional and you don't want to associate it
    parent { nil } # If it's optional and you don't want to associate it
  end


  factory :assignment do
    name {"Sample Assignment"}
    instructor { association(:instructor) }
    
  end

  factory :role do
    name { Faker::Name.name }
  end


  factory :instructor, class: Instructor do
    sequence(:name) { |n| "instructor#{n}".downcase }
    role { Role.find_or_create_by(name: 'Instructor') }
    full_name { '6, instructor' }
    password { 'sample_password' }
    parent_id { 1 }
    email { 'instructor6@gmail.com' }
    parent { create(:user) }
  end

    factory :course, class: Course do
      sequence(:name) { |n| "CSC517, test#{n}" }
      instructor { Instructor.first || association(:instructor) }
      directory_path {'csc517/test'}
      info {'Object-Oriented Languages and Systems'}
      private {true}
      institution { Institution.first || association(:institution) }
    end

    factory :institution, class: Institution do
      name {'North Carolina State University'}
    end
  factory :team do
    association :assignment
  end

  factory :sign_up_topic do
    association :assignment
  end

  factory :questionnaire do
    sequence(:name) { |n| "questionnaire#{n}".downcase }

    association :instructor
    max_question_score {2}
    min_question_score {1}
  end

  factory :assignment_questionnaire do
    association :assignment
    association :questionnaire
  end





end


# FactoryBot.define do
#   factory :user do
#     sequence(:name) { |n| "user#{n}" }
#     # sequence(:name) { |_n| Faker::Name.name.to_s.delete(" \t\r\n").downcase! }
#     sequence(:email) { |_n| Faker::Internet.email.to_s }
#     password { 'password' }
#     sequence(:full_name) { |_n| "#{Faker::Name.name}#{Faker::Name.name}".downcase }
#     role factory: :role
#     institution factory: :institution
#   end
#
#   factory :role do
#     name { Faker::Name.name }
#   end
#
#   factory :assignment do
#     sequence(:name) {|n| "assignment#{n}".downcase!}
#     instructor factory: :instructor
#
#   end
#
#   factory :invitation do
#     from_user factory: :user
#     to_user factory: :user
#     assignment factory: :assignment
#     reply_status { 'W' }
#   end
#
#   factory :institution, class: Institution do
#     name {'North Carolina State University'}
#   end
#
#   if ActiveRecord::Base.connection.table_exists?(:roles)
#     factory :role_of_instructor, class: Role do
#       name { 'Instructor' }
#       parent_id { nil }
#     end
#   end
#
#     factory :instructor, class: Instructor do
#       before(:create) { |instructor| instructor.name = instructor.name.downcase }
#       name { 'instructor6' }
#       role { Role.find_or_create_by(name: 'Instructor') }
#       full_name { '6, instructor' }
#       password { 'sample_password' }
#       parent_id { 1 }
#       email { 'instructor6@gmail.com' }
#       parent { create(:user) }
#     end
#
#   factory :course, class: Course do
#     sequence(:name) { |n| "CSC517, test#{n}" }
#     instructor { Instructor.first || association(:instructor) }
#     directory_path {'csc517/test'}
#     info {'Object-Oriented Languages and Systems'}
#     private {true}
#     institution { Institution.first || association(:institution) }
#   end
# end