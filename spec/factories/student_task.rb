FactoryBot.define do
    factory :student_task do
        assignment { nil }
        current_stage { "MyString" }
        participant { nil }
        stage_deadline { "2024-04-15 15:55:54" }
        topic { "MyString" }
    end
end
