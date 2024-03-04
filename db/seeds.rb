# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Create an admin user
admin_user = User.create!(
  name: 'admin',
  email: 'admin2@example.com',
  password: 'password123',
  full_name: 'admin admin',
  institution_id: 1
)
