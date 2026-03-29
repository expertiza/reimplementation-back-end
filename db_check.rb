
puts "--- Database Connection ---"
puts "Database: #{ActiveRecord::Base.connection.current_database}"
puts "DB Config: #{ActiveRecord::Base.connection_db_config.inspect}"

puts "\n--- Users (First 10) ---"
User.limit(10).each { |u| puts "ID: #{u.id}, Name: #{u.name}" }

puts "\n--- User 'isaac' ---"
isaac = User.find_by(name: 'isaac')
puts isaac.inspect

puts "\n--- Team 'Team_isaac_1' ---"
team = Team.find_by(name: 'Team_isaac_1')
puts team.inspect

puts "\n--- Questionnaires ---"
Questionnaire.all.each { |q| puts "ID: #{q.id}, Name: #{q.name}, Type: #{q.questionnaire_type}" }

puts "\n--- AssignmentQuestionnaires for Assignment 1 ---"
AssignmentQuestionnaire.where(assignment_id: 1).each do |aq|
  puts "Assignment: #{aq.assignment_id}, Questionnaire: #{aq.questionnaire_id} (#{aq.questionnaire&.name})"
end
