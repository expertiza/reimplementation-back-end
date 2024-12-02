begin
    #Create an instritution
    institution = Institution.create!(
      name: 'North Carolina State University'
    )
    
    Role.find_or_create_by(name: 'Admin')
    Role.find_or_create_by(name: 'Instructor')
    Role.find_or_create_by(name: 'Student')
    
    # Create an admin user
    User.create!(
      name: 'admin2',
      email: 'admin2@example.com',
      password: 'password123',
      full_name: 'admin admin',
      institution_id: 1,
      role_id: 1,
      handle: "admin"
    )

    instructor = User.create!(
      name: "Dr. Ed Gehringer1",
      email: "gehringer@example.com",
      password: "password123",
      full_name: 'admin admin',
      institution_id: 1,
      role_id: 2,
      handle: "instructor"
    )

    course = Course.create!(
      name: "2476. Refactor",
      directory_path: "/",
      info: "OODD",
      private: false,
      instructor_id: 1,
      institution_id: 1
    )

    assignment = Assignment.create!(
      title: "Project 4 BRO",
      description: "2476. Reimplemting",
      course_id: 1,
      instructor_id: 1
    )

    3.times do |i|
      user = User.create!(
        name: "Student #{i + 1}",
        email: "Student#{i + 1}@gmail.com",
        password: "password123",
        full_name: "Student #{i + 1}",
        institution_id: 1,
        role_id: 3,
        handle: "Student #{i + 1}"
      )
      
      AssignmentParticipant.create!(
        assignment: assignment,
        user: user,
        handle: "Student #{i + 1}"
      )
    end
rescue ActiveRecord::RecordInvalid => e
    puts e
end