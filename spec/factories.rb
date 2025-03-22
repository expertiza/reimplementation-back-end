FactoryBot.define do
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

  factory :response_map do
    # Define the necessary attributes for response_map
    reviewee { create(:user) }
    reviewer { create(:user) }
    id { 0 }
    reviewee_team { nil }
    type { 'ReviewResponseMap' }
    assignment { nil }
    title { nil }
  end

end
