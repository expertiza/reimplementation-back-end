FactoryBot.define do
  factory :participant_score do
    assignment_participant { nil }
    assignment { nil }
    question { nil }
    score { 1 }
    total_score { 1 }
    round { 1 }
  end

  factory :student_task do
    assignment { nil }
    current_stage { "MyString" }
    participant { nil }
    stage_deadline { "2024-04-15 15:55:54" }
    topic { "MyString" }
  end


  factory :join_team_request do
  end

  factory :bookmark do
    url { "MyText" }
    title { "MyText" }
    description { "MyText" }
    user_id { 1 }
    topic_id { 1 }
  end

  # Modify the user factory to include role and institution associations
  factory :user do
    sequence(:name) { |n| "user#{n}_#{Faker::Internet.username}" }
    sequence(:email) { |n| "user#{n}_#{Faker::Internet.email}" }
    password { 'password' }
    sequence(:full_name) { |n| "FullName#{n}_#{Faker::Name.name}" }
    association :institution

    # Default role can be set to 'student' or as per your application's default
    association :role, factory: :student_role

    trait :student do
      association :role, factory: :student_role
    end

    trait :instructor do
      association :role, factory: :instructor_role
    end

    trait :administrator do
      association :role, factory: :administrator_role
    end

    # Additional traits for other roles as needed
  end

  # Define role factories
  factory :role do
    name { "default_role" }  # Adjust as necessary

    factory :student_role do
      name { "student" }
      id { Role::STUDENT }  # Use constants or IDs as per your Role model
    end

    factory :instructor_role do
      name { "instructor" }
      id { Role::INSTRUCTOR }
    end

    factory :administrator_role do
      name { "administrator" }
      id { Role::ADMINISTRATOR }
    end

    # Define other roles similarly
  end

  factory :institution do
    sequence(:name) { |n| "Institution_#{n}_#{SecureRandom.hex(4)}" }
  end

  factory :instructor, parent: :user, class: 'Instructor' do
    # Any instructor-specific attributes
    # For STI, you might need to set the 'type' column
    type { 'Instructor' }
  end


  # spec/factories.rb
  factory :assignment do
    sequence(:title) { |n| "Assignment_#{n}_#{SecureRandom.hex(4)}" }
    association :course
    association :instructor, factory: :user  # Add this line

    has_badge { false }
    enable_pair_programming { false }
    is_calibrated { false }
    staggered_deadline { false }
    # Add other attributes as needed
  end


  factory :course do
    name { "Course_#{SecureRandom.hex(8)}" }
    directory_path { "directory_path_#{SecureRandom.hex(8)}" }
    instructor
    institution  # This allows the factory to use a provided institution
  end

  factory :assignment_participant do
    assignment
    user
    handle { user.name }
  end

  factory :assignment_questionnaire do
    assignment
    questionnaire
  end

  factory :team do
    assignment
  end

  factory :question do
    questionnaire
    txt { "Sample question text" }
    weight { 1 }
    question_type { "Criterion" }
    break_before { true }
    seq { 1 }  # Ensure sequence number is set
    # Add other attributes as needed
  end

  factory :questionnaire do
    name { "Sample Questionnaire" }
    max_question_score { 5 }
    min_question_score { 0 }
    private { false }
    association :instructor, factory: :user
  end
end
