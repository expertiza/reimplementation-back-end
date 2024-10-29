FactoryBot.define do
    factory :join_team_request do
        sequence(:message) { |n| "Join Team Request #{n}" }
    end
end
