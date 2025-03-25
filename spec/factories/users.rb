# spec/factories/users.rb
FactoryBot.factories.clear
FactoryBot.define do
    factory :user do
      email { Faker::Internet.email }
      password { 'password123' }
      password_confirmation { 'password123' }
      name { Faker::Name.first_name }
      full_name { Faker::Name.name } 
      association :role
      reset_password_sent_at { nil }
    end
  end
  