FactoryBot.define do
    factory :user do
        sequence(:name) { |_n| Faker::Name.name.to_s.delete(" \t\r\n").downcase }
        sequence(:email) { |_n| Faker::Internet.email.to_s }
        password { 'password123' }
        sequence(:full_name) { |_n| "#{Faker::Name.name} #{Faker::Name.name}".downcase }
    
        # Use the existing 'Student' role if available
        role { Role.find_by(name: 'Student') || association(:role, name: 'Student') }

        # Use the existing 'North Carolina State University' institution if available
        institution { Institution.find_by(name: 'North Carolina State University') || association(:institution, name: 'North Carolina State University') }
    end
end
