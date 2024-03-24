begin
    #Create an instritution
    Institution.create!(
      name: 'North Carolina State University',
    )
    
    # Create an admin user
    User.create!(
      name: 'admin',
      email: 'admin2@example.com',
      password: 'password123',
      full_name: 'admin admin',
      institution_id: 1,
      role_id: 1
    )
rescue ActiveRecord::RecordInvalid => e
    puts 'The db has already been seeded'
end