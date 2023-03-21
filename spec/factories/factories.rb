FactoryBot.define do
  factory :user do
    name {"user"}
    crypted_password {'1111111111111111111111111111111111111111'}
    role_id {0}
  end
  factory :response do
    map_id {0}
  end
end