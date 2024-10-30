FactoryBot.define do
    factory :assignment do
        sequence(:name) { |n| "Assignment #{n}" }

        # Search the database for someone with the instructor role
        instructor_id { User.find_by(role: Role.find_by(name: 'Instructor'))&.id || association(:user, role: association(:role, name: 'Instructor')).id }
    end
end