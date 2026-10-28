# frozen_string_literal: true

# spec/factories/questionnaires.rb
FactoryBot.define do
  factory :questionnaire do
    sequence(:name) { |n| "Questionnaire #{n}" }
    private { false }
    min_item_score { 0 }
    max_item_score { 10 }
    association :instructor
    association :assignment

    # Trait for questionnaire with questions
    trait :with_questions do
      after(:create) do |questionnaire|
        create(:item, questionnaire: questionnaire, weight: 1, seq: 1, txt: "que 1", item_type: "Scale")
        create(:item, questionnaire: questionnaire, weight: 10, seq: 2, txt: "que 2", item_type: "Checkbox")
      end
    end
  end
end

# spec/factories/items.rb
FactoryBot.define do
  factory :item do
    sequence(:txt) { |n| "Question #{n}" }
    sequence(:seq) { |n| n }
    weight { 1 }
    item_type { "Scale" }
    break_before { true }
    association :questionnaire
  end
end