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

  factory :user do
    sequence(:name) { |_n| Faker::Name.name.to_s.delete(" \t\r\n").downcase }
    sequence(:email) { |_n| Faker::Internet.email.to_s }
    password { 'password' }
    sequence(:full_name) { |_n| "#{Faker::Name.name}#{Faker::Name.name}".downcase }
    role factory: :role
    institution factory: :institution
  end

end
