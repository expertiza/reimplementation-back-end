FactoryBot.define do
  factory :suggestion do
    title { 'Sample Suggestion' }
    description { 'This is a sample suggestion description.' }
    status { 'Initialized' }
    auto_signup { false }
    assignment_id { create(:assignment).id } # Ensure an assignment exists
    user_id { create(:user).id } # Ensure a user exists
  end
end
