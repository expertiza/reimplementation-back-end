# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name) { |_n| Faker::Name.name.to_s.delete(" \t\r\n").downcase }
    sequence(:email) { |_n| Faker::Internet.email.to_s }
    password { 'password' }
    sequence(:full_name) { |_n| "#{Faker::Name.name}#{Faker::Name.name}".downcase }
    role factory: :role
    institution factory: :institution

    trait :instructor do
      role { create(:role, :instructor) }
    end

    trait :ta do
      role { create(:role, :ta) }
    end

    trait :student do
      role { create(:role, :student) }
    end

    trait :administrator do
      role { create(:role, :administrator) }
    end
  end

  factory :password_reset_user, parent: :user, class: 'User' do
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
  