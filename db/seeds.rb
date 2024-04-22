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

    # Create an admin user
    User.create!(
      name: 'john',
      email: 'user@example.com',
      password: 'password123',
      full_name: 'John',
      institution_id: 1,
      role_id: 1
    )

    # db/seeds.rb

    # Insert 5 assignments into the 'assignments' table
    Assignment.create!([{
                           name: 'Rails Assignment',
                           directory_path: '/OODD/assignments/2',
                           submitter_count: 0,
                           course_id: 1,
                           instructor_id: 3,
                           private: false,
                           num_reviews: 0,
                           created_at: Time.current,
                           updated_at: Time.current
                         },
                         {
                           name: 'Ruby Assignment',
                           directory_path: '/OODD/assignments/3',
                           submitter_count: 0,
                           course_id: 1,
                           instructor_id: 3,
                           private: false,
                           num_reviews: 0,
                           created_at: Time.current,
                           updated_at: Time.current
                         },
                         {
                           name: 'Design Pattern Assignment',
                           directory_path: '/OODD/assignments/4',
                           submitter_count: 0,
                           course_id: 1,
                           instructor_id: 3,
                           private: false,
                           num_reviews: 0,
                           created_at: Time.current,
                           updated_at: Time.current
                         },
                         {
                           name: 'Code Principles Assignment',
                           directory_path: '/OODD/assignments/5',
                           submitter_count: 0,
                           course_id: 1,
                           instructor_id: 3,
                           private: false,
                           num_reviews: 0,
                           created_at: Time.current,
                           updated_at: Time.current
                         },
                         {
                           name: 'Object Oriented Assignment',
                           directory_path: '/OODD/assignments/6',
                           submitter_count: 0,
                           course_id: 1,
                           instructor_id: 3,
                           private: false,
                           num_reviews: 0,
                           created_at: Time.current,
                           updated_at: Time.current
                         }
                       ])

    Participant.create!([
                          {
                            user_id: 2,
                            assignment_id: 1,
                            topic: 'Rails Assignment',
                            current_stage: 'In Progress',
                            stage_deadline: Time.now + (7*24*60*60),
                            created_at: Time.current,
                            updated_at: Time.current,
                            permission_granted: false
                          },
                          {
                            user_id: 2,
                            assignment_id: 2,
                            topic: 'Ruby Assignment',
                            current_stage: 'In Progress',
                            stage_deadline: Time.now + (7*24*60*60),
                            created_at: Time.current,
                            updated_at: Time.current,
                            permission_granted: false
                          },
                          {
                            user_id: 2,
                            assignment_id: 3,
                            topic: 'Design Pattern Assignment',
                            current_stage: 'In Progress',
                            stage_deadline: Time.now + 2 * (7*24*60*60),
                            created_at: Time.current,
                            updated_at: Time.current,
                            permission_granted: true
                          },
                          {
                            user_id: 2,
                            assignment_id: 4,
                            topic: 'Code Principles Assignment',
                            current_stage: 'In Progress',
                            stage_deadline: Time.now + (3*7*24*60*60),
                            created_at: Time.current,
                            updated_at: Time.current,
                            permission_granted: true
                          },
                          {
                            user_id: 2,
                            assignment_id: 5,
                            topic: 'Object Oriented Assignment',
                            current_stage: 'In Progress',
                            stage_deadline: Time.now + (4*7*24*60*60),
                            created_at: Time.current,
                            updated_at: Time.current,
                            permission_granted: false
                          }
                        ])

    Course.create!([
                     {
                       name: "CSC/ECE517- Object-Oriented Design and Development",
                       directory_path: "/CSC_ECE_517/",
                       info: "This is a test data, please improve it later if necessary",
                       private: false,
                       created_at: Time.now,
                       updated_at: Time.now,
                       instructor_id: 1,
                       institution_id: 1
                     }
                   ])
rescue ActiveRecord::RecordInvalid => e
  puts e.backtrace
  puts 'The db has already been seeded'
end