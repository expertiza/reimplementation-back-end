# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    # sequence(:name) { |n| "Role #{n}" }

    sequence(:id) { |n| n } # Ensures unique IDs for roles without traits
    initialize_with { Role.find_or_create_by(id: id) }

    # initialize_with do
    #   Role.find_or_create_by(id: id) do |role|
    #     role.name = name
    #   end
    # end

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

# spec/factories/teams.rb
FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
  end
end