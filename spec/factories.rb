FactoryBot.define do

  factory :participant_score do
    association :assignment_participant, factory: :assignment_participant
    assignment { assignment_participant.assignment }
    question
    score { 90 }
    total_score { 100 }
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

  factory :user do
    sequence(:name) { |n| "user#{n}_#{Faker::Internet.username}" }
    sequence(:email) { |n| "user#{n}_#{Faker::Internet.email}" }
    password { 'password' }
    full_name { Faker::Name.name }
    institution
    role { Role.find_by(name: 'student') || create(:role, name: 'student') }

  end

  factory :review_mapping do
    assignment_participant
    # add any other necessary attributes here
  end

  factory :instructor, class: 'Instructor' do
    sequence(:name) { |n| "instructor#{n}_#{Faker::Internet.username}" }
    sequence(:email) { |n| "instructor#{n}_#{Faker::Internet.email}" }
    password { 'password' }
    full_name { Faker::Name.name }
    institution
    role { Role.find_by(name: 'instructor') || create(:role, name: 'instructor') }
  end

  factory :institution do
    sequence(:name) { |n| "Institution_#{n}_#{SecureRandom.hex(4)}" }
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
    skip_create
    name { "Sample Questionnaire" }
    max_question_score { 5 }
    min_question_score { 0 }
    private { false }
    instructor
  end
end
