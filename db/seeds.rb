# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
role = Role.find(2)
Role.create(name: "xxx", parent_id: 1).save
user = User.create(name: "admin", full_name: "admin", role_id: 2, institution_id: 1)
user.save