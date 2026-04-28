# frozen_string_literal: true

# spec/factories/question_advice.rb
FactoryBot.define do
    factory :question_advice do
        score {5}
        association :item
        advice {'default advice'}
    end

end