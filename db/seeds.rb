begin
    #Create an institution
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

    Questionnaire.create!(
      name: 'Questionnaire',
      instructor_id: 2,
      min_question_score: 0,
      max_question_score: 10,
      private: false,
      questionnaire_type: 'AuthorFeedbackReview'
    )

    Question.create!(
      seq: 1,
      txt: "test question 1",
      question_type: "multiple_choice",
      break_before: true,
      weight: 5,
      questionnaire_id: 1
    )

    Question.create!(
      seq: 2,
      txt: "test question 2",
      question_type: "multiple_choice",
      break_before: false,
      weight: 5,
      questionnaire_id: 1
    )


rescue ActiveRecord::RecordInvalid => e
    puts 'The db has already been seeded'
end
