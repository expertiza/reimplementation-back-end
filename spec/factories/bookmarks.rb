# spec/factories/bookmark.rb

FactoryBot.define do
    factory :bookmark do
        url { "http://example.com" }
        title { "Example Bookmark" }
        description { "An example bookmark description" }
    
        # Use associations instead of hardcoded IDs
        association :user
        association :topic
    end
end
