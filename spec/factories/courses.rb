FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "Course #{n}" }
    sequence(:directory_path) { |n| "course_#{n}" }
    association :instructor, factory: [:user, :instructor]
    association :institution
  end
end