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

    User.create!(
      name: 'instructor',
      email: 'instructor@example.com',
      password: 'password123',
      full_name: 'instructor instructor',
      institution_id: 1,
      role_id: 3
    )

    User.create!(
      name: 'student',
      email: 'student@example.com',
      password: 'password123',
      full_name: 'student student',
      institution_id: 5,
      role_id: 5
    )


rescue ActiveRecord::RecordInvalid => e
    puts 'The db has already been seeded'
end
