FactoryBot.define do

  factory :user do
    sequence(:name) { |n| n = n % 3; "student206#{n + 4}" }
    email { "joe@gmail.com" }
    password { "blahblahblah" }
    sequence(:fullname) { |n| n = n % 3; "206#{n + 4}, student" }
    role factory: :role
  end

  factory :role do
    name { "Student" }
  end

  factory :assignment do
    name { (Assignment.last ? ('assignment' + (Assignment.last.id + 1).to_s) : 'final2').to_s }
  end
end