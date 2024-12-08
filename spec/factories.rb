FactoryBot.define do
  factory :student_task do
    assignment { nil }
    current_stage { 'MyString' }
    participant { nil }
    stage_deadline { '2024-04-15 15:55:54' }
    topic { 'MyString' }
  end

  factory :join_team_request do
  end

  factory :bookmark do
    url { 'MyText' }
    title { 'MyText' }
    description { 'MyText' }
    user_id { 1 }
    topic_id { 1 }
  end

  factory :role do
    name { Faker::Name.name }
  end

  factory :institution, class: Institution do
    name { 'North Carolina State University' }
  end

  factory :assignment do
    title { 'Sample Assignment' }
    description { 'Description for the assignment' }
    instructor { create(:instructor) }
  end

  factory :instructor, class: Instructor do
    name { 'Dummy instructor' }
    password { 'test123' }
    email { 'test@gmail.com' }
    full_name { 'Dummy Instructor' }
    role factory: :role
  end

  factory :user do
    sequence(:name) { |n| Faker::Name.name.to_s.delete(" \t\r\n").downcase + n.to_s }
    sequence(:email) { |_n| Faker::Internet.email.to_s }
    password { 'password' }
    sequence(:full_name) { |_n| "#{Faker::Name.name}#{Faker::Name.name}".downcase }
    role factory: :role
    institution factory: :institution
  end
end
