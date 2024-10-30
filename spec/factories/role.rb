FactoryBot.define do
    factory :role do
        id { Role.find_by(name: 'Student').id || 5 }
        name { 'Student' } # Adjust this as needed
    end
  end
  