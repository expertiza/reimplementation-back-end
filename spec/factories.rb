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

  # Define the required role factory
  factory :role do
    name { "default_role" }  # Adjust as needed for your Role model
  end

  # Define the required institution factory
  factory :institution do
    name { "default_institution" }  # Adjust based on Institution model requirements
  end

  # Modify the user factory to include role and institution associations
  factory :user do
    sequence(:name) { |n| "user#{n}_#{Faker::Internet.username}" }
    sequence(:email) { |n| "user#{n}_#{Faker::Internet.email}" }
    password { 'password' }
    sequence(:full_name) { |n| "FullName#{n}_#{Faker::Name.name}" }
    association :role
    association :institution
  end


  # spec/factories.rb
  factory :assignment do
    sequence(:title) do |n|
      assignment_title = "Assignment_#{n}_#{SecureRandom.hex(4)}"
      puts "Generated Assignment title: #{assignment_title}"
      assignment_title
    end
    association :course
    association :instructor, factory: :user
    has_badge { false }
    enable_pair_programming { false }
    is_calibrated { false }
    staggered_deadline { false }
  end


  factory :course do
    sequence(:name) { |n| "Course #{n}" }
    association :institution
    association :instructor, factory: :user
    sequence(:directory_path) { |n| "directory_path_#{n}" } # Ensures unique directory paths
  end

end
