# Expertiza Backend Re-Implementation

---

Expertiza is a Ruby on Rails based open source project. Instructors have the ability to add new projects, assignments, etc., as well as edit existing ones. Later on, they can view student submissions and grade them. Students can also use Expertiza to organize into teams to work on different projects and assignments and submit their work. They can also review other students' submissions.

## Setup

---

### Steps:
- bundle install
- rake db:create
- rake db:migrate
- db:schema:load

### Steps for Testing:
* To populate the database with temporary data, run: <br>
  - rake db:seed RAILS_ENV=test
* To run tests:
  - rspec spec/
* To run tests with list of passing/failing tests:
  - rspec -f d spec/