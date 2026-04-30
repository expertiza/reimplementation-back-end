FactoryBot.define do
  factory :response do
    map_id { 1 }
    is_submitted { false }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
