# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
institution1 = Institution.create!(
  name: 'Purdue'
)

admin = User.create!(
  name: 'admin',
  password_digest: BCrypt::Password.create('admin'), # Hashed password
  full_name: 'John A. Doe',
  email: 'john.doe@example.com',
  mru_directory_path: '/path/to/directory',
  email_on_review: true,
  email_on_submission: false,
  email_on_review_of_review: true,
  is_new_user: true,
  master_permission_granted: false,
  handle: 'johndoe',
  persistence_token: 'token123',
  timeZonePref: 'UTC',
  copy_of_emails: false,
  etc_icons_on_homepage: true,
  locale: 1,
  role_id: 2,
  institution: institution1,
  )

instructor1 = User.create!(
  name: 'instructora',
  password_digest: BCrypt::Password.create('password'), # Hashed password
  full_name: 'John A. Doe',
  email: 'instructor.ins@example.com',
  mru_directory_path: '/path/to/directory',
  email_on_review: true,
  email_on_submission: false,
  email_on_review_of_review: true,
  is_new_user: true,
  master_permission_granted: false,
  handle: 'instruct',
  persistence_token: 'token123',
  timeZonePref: 'UTC',
  copy_of_emails: false,
  etc_icons_on_homepage: true,
  locale: 1,
  role_id: 3,
  institution: institution1,
  )

course = Course.create!(
  name: 'Introduction to Programming',
  directory_path: '/programming101',
  info: 'This is an introductory course on programming.',
  private: false,
  instructor: instructor1,
  institution: institution1
)

