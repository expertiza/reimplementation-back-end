FactoryBot.define do
    factory :submission do
      user
      content { "Sample content for the submission." }
      created_at { Time.now }
    end
  end