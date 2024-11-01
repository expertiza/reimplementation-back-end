FactoryBot.define do
    factory :course do
        sequence(:name) { |n| "Course #{n}" }
        sequence(:directory_path) { |n| "/course_#{n}/" }

        # Search the database for someone with the instructor role
        instructor_id { User.find_by(role: Role.find_by(name: 'Instructor'))&.id || association(:user, role: association(:role, name: 'Instructor')).id }

        # Use the existing 'North Carolina State University' institution if available
        institution_id { Institution.find_by(name: 'North Carolina State University')&.id || association(:institution, name: 'North Carolina State University').id }
    end
end