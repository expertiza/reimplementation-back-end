# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role#{n}" }

    trait :student do
      id { Role::STUDENT }
      name { 'Student' }
    end

    trait :ta do
      id { Role::TEACHING_ASSISTANT }
      name { 'Teaching Assistant' }
    end

    trait :instructor do
      id { Role::INSTRUCTOR }
      name { 'Instructor' }
    end

    trait :administrator do
      id { Role::ADMINISTRATOR }
      name { 'Administrator' }
    end

    trait :super_administrator do
      id { Role::SUPER_ADMINISTRATOR }
      name { 'Super Administrator' }
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