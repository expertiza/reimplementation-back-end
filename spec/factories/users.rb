# Existing factory (just enhance it)
FactoryBot.define do
    factory :user do
      sequence(:name) { |n| "User #{n}" }
      full_name { "Test User #{SecureRandom.hex(2)}" }
      sequence(:email) { |n| "user#{n}@example.com" }
      password { "password123" }
      institution
      role { Role.find_or_create_by(id: Role::STUDENT) }
  
      trait :student do
        role { create(:role, :student) }
      end
  
      trait :ta do
        role { create(:role, :ta) }
      end
  
      trait :instructor do
        role { create(:role, :instructor) }
      end
  
      trait :administrator do
        role { create(:role, :administrator) }
      end
  
      trait :super_administrator do
        role { create(:role, :super_administrator) }
      end
    end
  end
  