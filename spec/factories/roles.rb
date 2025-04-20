# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }

    trait :student do
      sequence(:name) { |n| "Student #{n}" }
    end

    trait :ta do
      sequence(:name) { |n| "Teaching Assistant #{n}" }
    end

    trait :instructor do
      sequence(:name) { |n| "Instructor #{n}" }
    end

    trait :administrator do
      sequence(:name) { |n| "Administrator #{n}" }
    end

    trait :super_administrator do
      sequence(:name) { |n| "Super Administrator #{n}" }
    end

    trait :mentor do
      sequence(:name) { |n| "Mentor #{n}" }
    end

    # Add a trait to create roles with a parent
    trait :with_parent do
      transient do
        parent { nil }
      end

      after(:create) do |role, evaluator|
        role.update(parent_id: evaluator.parent.id) if evaluator.parent
      end
    end
  end
end

# spec/factories/institutions.rb
FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }
  end
end

# spec/factories/teams_users.rb
FactoryBot.define do
  factory :teams_user do
    association :user
    association :team
  end
end