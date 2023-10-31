# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if ENV['SEED']

  institutions = Institution.where(name: "NCSU")

  if institutions.count == 0
    institute = Institution.create(name: "NCSU")
    @institution_id = institute.id
    institute.save!
  else
    @institution_id = institutions.first.id
  end

  users = User.where(name: "admin")

  if users.count == 0
    User.create(name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: @institution_id).save!
  end

  if User.where(name: "pone").count == 0
    User.create(name: "pone", full_name: "p1", email: "pone@gmail.com", password_digest: "pone", role_id: 5, institution_id: @institution_id).save!
  end



  if Assignment.where(name: "QuizAssignment1").count == 0
    assignment = Assignment.create(name: "QuizAssignment1", require_quiz: true).save!
  end

  if Team.where(name: "team1").count == 0
    Team.create(name: "team1").save!
  end
  team_id = Team.where(name: "team1").first.id

  participant_user_id = User.where(name: "pone").first.id
  assignment_id = Assignment.where(name: "QuizAssignment1").first.id
  if Participant.where(user_id: participant_user_id).count == 0
    participant = Participant.create(user_id: participant_user_id, assignment_id: assignment_id, team_id: team_id).save!
  end

  # if AssignmentQuestionnaire.where(assignment_id: assignment_id).count == 0
  #   AssignmentQuestionnaire.create(assignment_id: assignment_id, notification_limit: 5, questionnaire_id: 1).save!
  # end


end
# SEED=true rails db:seed

if ENV['UNDO_SEED']
  Institution.where(name: ['NCSU']).destroy_all
  User.where(name: ['admin']).destroy_all
end
# UNDO_SEED=true rails db:seed