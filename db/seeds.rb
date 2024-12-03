begin
  #Create an instritution
  ncsu = Institution.create!(
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
    name: 'ta_user',
    email: 'ta_user@example.com',
    password: 'password123',
    full_name: 'Teaching Assistant',
    institution_id: 1, # Replace with appropriate institution ID
    role_id: 4 # Role ID for Teaching Assistant
  )

  User.create!(
    name: 'ta_user_2',
    email: 'ta_user2@example.com',
    password: 'password123',
    full_name: 'Teaching Assistant 2',
    institution_id: 1, # Replace with appropriate institution ID
    role_id: 4 # Role ID for Teaching Assistant
  )

  User.create!(
    name: 'student_user_1',
    email: 'student_user1@example.com',
    password: 'password123',
    full_name: 'Student 1',
    institution_id: 1, # Replace with appropriate institution ID
    role_id: 5 # Role ID for Teaching Assistant
  )

  User.create!(
    name: 'student_user_2',
    email: 'student_user2@example.com',
    password: 'password123',
    full_name: 'Student 2',
    institution_id: 1, # Replace with appropriate institution ID
    role_id: 5 # Role ID for Teaching Assistant
  )
  
  instructor = User.create!(
    name: 'instructor1',
    email: 'instructor1@example.com',
    password: 'password123',
    full_name: 'Instructor One',
    institution_id: ncsu.id,
    role_id: 2
  )

  course = Course.create!(
    name: 'Intro to Expertiza',
    directory_path: 'expertiza_intro',
    info: 'An introductory course on the Expertiza platform',
    private: false,
    instructor_id: instructor.id,
    institution_id: ncsu.id
  )

  assignment = Assignment.create!(
    name: 'Sample Assignment',
    directory_path: 'sample_assignment',
    submitter_count: 1,
    private: false,
    num_reviews: 3,
    num_review_of_reviews: 2,
    reviews_visible_to_all: true,
    spec_location: 'http://example.com/specs/sample_assignment',
    max_team_size: 3,
    instructor_id: instructor.id,
    course_id: course.id
  )
rescue ActiveRecord::RecordInvalid => e
  puts 'The db has already been seeded'
end