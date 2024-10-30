# spec/factories/bookmark.rb

FactoryBot.define do
    factory :bookmark do
        url { Faker::Internet.url }
        title { Faker::Lorem.sentence }
        description { Faker::Lorem.paragraph }
    
        # Search the database for a user with the student role
        user_id { User.find_by(role: Role.find_by(name: 'Student'))&.id || association(:user, role: association(:role, name: 'Student')).id }

        association :topic_id, factory: :sign_up_topic
    end
end
