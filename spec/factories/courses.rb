FactoryBot.define do
  factory :course do
    name { Faker::Educator.course_name }
    info { Faker::Lorem.paragraph }
    private { false }
    directory_path { Faker::File.dir }
    association :institution, factory: :institution
    association :instructor, factory: :user
  end
end
