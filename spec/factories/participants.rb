FactoryBot.define do
  factory :participant do
    association :user
    association :assignment
    can_submit { false }
    can_review { false }
    can_take_quiz { false }
    can_mentor { false }
  end
end