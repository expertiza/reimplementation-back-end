FactoryBot.define do
    factory :bookmark do
        url { "MyText" }
        title { "MyText" }
        description { "MyText" }
        user_id { 1 }
        topic_id { 1 }
    end
end
