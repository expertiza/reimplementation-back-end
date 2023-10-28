# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


institutions = Institution.where(name: "NCSU")
institution_id = institutions.first.id

if institutions.count == 0
  Institution.create(name: "NCSU").save!
end

users = User.where(name: "admin")

if users.count == 0
  ser.create(name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: 2).save!
end


# if ENV['UNDO_SEED']
#   Institution.where(name: ['NCSU']).destroy_all
#   User.where(name: ['admin']).destroy_all
# end
#UNDO_SEED=true rails db:seed