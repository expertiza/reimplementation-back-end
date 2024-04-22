


-- to start up app and SQL services on backedn

rails terminal:
docker compose up


-- Not too sure what this is exactly for
bundle install
rake db:create
rake db:migrate



-- app service
rails s -p 4000 -b '0.0.0.0'

-- SQL service
mysql -u dev -pexpertiza
use reimplementation_development;


-- Creating test objects in SQL



-- Create roles
INSERT INTO roles (name, created_at, updated_at) VALUES ('Student', NOW(), NOW());
INSERT INTO roles (name, created_at, updated_at) VALUES ('Instructor', NOW(), NOW());


-- Insert a user
INSERT INTO users (
  name,
  password_digest,
  full_name,
  email,
  role_id,
  institution_id,
  created_at,
  updated_at
) VALUES (
  'testuser',
  'password',
  'Test User',
  'testuser@example.com',
  5,  -- Assuming 1 is the ID for the role
  1,  -- Assuming 1 is the ID for the institution
  NOW(),
  NOW()
);



-- Insert an assignment
INSERT INTO assignments (
  name,
  directory_path,
  course_id,
  instructor_id,
  created_at,
  updated_at
) VALUES (
  'Test Assignment',
  '/path/to/assignment',
  1,  -- Assuming 1 is a valid course_id
  (SELECT id FROM users WHERE name = 'testuser'),  -- This selects the ID of the user you just inserted
  NOW(),
  NOW()
);


-- Created a new instructor, pretty sure the name field is full_name and there is also an password
-- field and institution_id.
-- Edited necesarry fields manually in RubyMine IDE

INSERT INTO users (name, email, password_digest, created_at, updated_at, role_id)
VALUES ('instructor_name', 'instructor_email', 'password_digest_here', NOW(), NOW(), (SELECT id FROM roles WHERE name = 'Instructor'));



SELECT * FROM users WHERE full_name = 'Test Instructor';


-- Inserting new test course
INSERT INTO courses (name, instructor_id, institution_id, created_at, updated_at)
VALUES ('Test Course', 3, 1, NOW(), NOW());
