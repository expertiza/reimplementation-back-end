# spec/factories/bookmark_ratings.rb

FactoryBot.define do
  factory :bookmark_rating do
    bookmark { nil }
    user { nil }
    rating { 0 }
  end
end