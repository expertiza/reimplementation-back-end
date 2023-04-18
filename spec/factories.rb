FactoryBot.define do

  factory :user do
    sequence(:name) { |n| "#{Faker::Name.name}".delete(" \t\r\n").downcase }
    sequence(:email) { |n| "#{Faker::Internet.email}"}
    password { "blahblahblah" }
    sequence(:fullname) { |n| "#{Faker::Name.name}#{Faker::Name.name}".downcase  }
    role factory: :role
  end

  factory :role do
    name { Faker::Name.name}
  end

  factory :assignment do
    name { (Assignment.last ? ('assignment' + (Assignment.last.id + 1).to_s) : 'final2').to_s }
  end

  factory :invitation do
    from_user factory: :user
    to_user factory: :user
    assignment factory: :assignment
    reply_status { "W" }
  end
end