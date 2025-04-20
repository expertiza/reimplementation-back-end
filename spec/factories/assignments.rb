FactoryBot.define do
  factory :assignment do
    transient do
      assignment_number { Faker::Number.unique.number(digits: 2) }
    end

    name { "Assignment #{assignment_number}" }
    directory_path { "assignment_#{assignment_number}" }

    # Required associations
    association :instructor, factory: [:user, :instructor]

    # Default values
    num_reviews { 3 }
    num_reviews_required { 3 }
    num_reviews_allowed { 3 }
    num_metareviews_required { 3 }
    num_metareviews_allowed { 3 }
    rounds_of_reviews { 1 }

    # Boolean flags
    is_calibrated { false }
    has_badge { false }
    enable_pair_programming { false }
    staggered_deadline { false }
    show_teammate_reviews { false }
    is_coding_assignment { false }

    # Optional association
    course { nil }

    trait :with_course do
      association :course
    end

    trait :with_badge do
      has_badge { true }
    end

    trait :with_teams do
      after(:create) do |assignment|
        create_list(:team, 2, assignment: assignment)
      end
    end

    trait :with_participants do
      after(:create) do |assignment|
        create_list(:participant, 2, assignment: assignment)
      end
    end

    trait :with_questionnaires do
      after(:create) do |assignment|
        create(:assignment_questionnaire, assignment: assignment)
      end
    end
  end
end
