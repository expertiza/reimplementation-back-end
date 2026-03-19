# Script to add test data for signup sheet with advertisements

puts "Starting to add test data for signup sheet..."

# Find or create an assignment
assignment = Assignment.first
unless assignment
  puts "Creating test assignment..."
  assignment = Assignment.create!(
    name: "Test Assignment - Final Project",
    directory_path: "/test",
    submitter_count: 0,
    course_id: 1,
    instructor_id: 2,
    private: false,
    num_reviews: 3,
    num_review_of_reviews: 1,
    num_review_of_reviewers: 1,
    reviews_visible_to_all: true,
    num_reviewers: 3,
    spec_link: "https://example.com/spec",
    max_team_size: 4,
    staggered_deadline: false,
    allow_suggestions: false,
    days_between_submissions: 7,
    review_assignment_strategy: "Auto-Selected",
    max_reviews_per_submission: 3,
    review_topic_threshold: 0,
    copy_flag: false,
    rounds_of_reviews: 1,
    microtask: false,
    require_quiz: false,
    num_quiz_questions: 0,
    is_calibrated: false,
    availability_flag: true,
    use_bookmark: true,
    can_review_same_topic: true,
    can_choose_topic_to_review: true,
    is_intelligent: false,
    calculate_penalty: false,
    late_policy_id: nil,
    is_penalty_calculated: false,
    max_choosing_teams: 1,
    is_anonymous: true,
    num_reviews_required: 3,
    num_metareviews_required: 1,
    num_reviews_allowed: 3,
    num_metareviews_allowed: 3,
    simicheck: -1,
    simicheck_threshold: 100
  )
  puts "Created assignment: #{assignment.name} (ID: #{assignment.id})"
end

puts "Using assignment: #{assignment.name} (ID: #{assignment.id})"

# Create sign up topics if they don't exist
topics_data = [
  { name: "Ruby on Rails Best Practices", max_choosers: 3, description: "Study and present best practices in Rails development" },
  { name: "React Frontend Development", max_choosers: 2, description: "Build a modern React application" },
  { name: "API Design and Documentation", max_choosers: 3, description: "Design and document RESTful APIs" },
  { name: "Database Optimization", max_choosers: 2, description: "Performance tuning for MySQL databases" }
]

topics = []
topics_data.each_with_index do |topic_data, index|
  topic = ProjectTopic.find_or_create_by!(
    topic_name: topic_data[:name],
    assignment_id: assignment.id
  ) do |t|
    t.topic_identifier = (index + 1).to_s
    t.max_choosers = topic_data[:max_choosers]
    t.category = "Project Topics"
    t.description = topic_data[:description]
  end
  topics << topic
  puts "Created/found topic: #{topic.topic_name} (ID: #{topic.id})"
end

# Find the student users
user1 = User.find_by(name: "quinn_johns")
user2 = User.find_by(name: "gaston_blick") || User.find_by(role_id: 3).second
user3 = User.where(role_id: 3).where.not(id: [user1&.id, user2&.id]).first

unless user1
  puts "ERROR: User quinn_johns not found!"
  exit 1
end

puts "Found users: #{user1.name}, #{user2&.name || 'N/A'}, #{user3&.name || 'N/A'}"

# Create assignment participants if they don't exist
participant1 = AssignmentParticipant.find_or_create_by!(
  user_id: user1.id,
  parent_id: assignment.id
) do |p|
  p.can_submit = true
  p.can_review = true
  p.can_take_quiz = true
  p.handle = user1.handle || user1.name
end
puts "Created/found participant for #{user1.name} (ID: #{participant1.id})"

participant2 = nil
if user2
  participant2 = AssignmentParticipant.find_or_create_by!(
    user_id: user2.id,
    parent_id: assignment.id
  ) do |p|
    p.can_submit = true
    p.can_review = true
    p.can_take_quiz = true
    p.handle = user2.handle || user2.name
  end
  puts "Created/found participant for #{user2.name} (ID: #{participant2.id})"
end

participant3 = nil
if user3
  participant3 = AssignmentParticipant.find_or_create_by!(
    user_id: user3.id,
    parent_id: assignment.id
  ) do |p|
    p.can_submit = true
    p.can_review = true
    p.can_take_quiz = true
    p.handle = user3.handle || user3.name
  end
  puts "Created/found participant for #{user3.name} (ID: #{participant3.id})"
end

# Create teams
team1 = AssignmentTeam.find_or_create_by!(
  name: "Team Alpha",
  parent_id: assignment.id
) do |t|
  t.type = "AssignmentTeam"
end
puts "Created/found team: #{team1.name} (ID: #{team1.id})"

team2 = nil
if user2
  team2 = AssignmentTeam.find_or_create_by!(
    name: "Team Beta",
    parent_id: assignment.id
  ) do |t|
    t.type = "AssignmentTeam"
  end
  puts "Created/found team: #{team2.name} (ID: #{team2.id})"
end

team3 = nil
if user3
  team3 = AssignmentTeam.find_or_create_by!(
    name: "Team Gamma",
    parent_id: assignment.id
  ) do |t|
    t.type = "AssignmentTeam"
  end
  puts "Created/found team: #{team3.name} (ID: #{team3.id})"
end

# Add users to teams
TeamsUser.find_or_create_by!(team_id: team1.id, user_id: user1.id)
puts "Added #{user1.name} to #{team1.name}"

if user2 && team2
  TeamsUser.find_or_create_by!(team_id: team2.id, user_id: user2.id)
  puts "Added #{user2.name} to #{team2.name}"
end

if user3 && team3
  TeamsUser.find_or_create_by!(team_id: team3.id, user_id: user3.id)
  puts "Added #{user3.name} to #{team3.name}"
end

# Sign up teams for topics with advertisements
# Team 1 signs up for Topic 1 and advertises for partners
signed_up_team1 = SignedUpTeam.find_or_create_by!(
  team_id: team1.id,
  project_topic_id: topics[0].id
) do |sut|
  sut.is_waitlisted = false
  sut.preference_priority_number = 1
  sut.advertise_for_partner = true
  sut.comments_for_advertisement = "Looking for experienced Ruby developers! We have strong frontend skills and need backend expertise. Great team dynamic!"
end
puts "Team #{team1.name} signed up for topic '#{topics[0].topic_name}' WITH advertisement"

# Team 2 signs up for Topic 2 and advertises
if team2
  signed_up_team2 = SignedUpTeam.find_or_create_by!(
    team_id: team2.id,
    project_topic_id: topics[1].id
  ) do |sut|
    sut.is_waitlisted = false
    sut.preference_priority_number = 1
    sut.advertise_for_partner = true
    sut.comments_for_advertisement = "Seeking creative frontend developer for React project. We have backend covered and need someone passionate about UX/UI design!"
  end
  puts "Team #{team2.name} signed up for topic '#{topics[1].topic_name}' WITH advertisement"
end

# Team 3 signs up for Topic 3 WITHOUT advertising
if team3
  signed_up_team3 = SignedUpTeam.find_or_create_by!(
    team_id: team3.id,
    project_topic_id: topics[2].id
  ) do |sut|
    sut.is_waitlisted = false
    sut.preference_priority_number = 1
    sut.advertise_for_partner = false
  end
  puts "Team #{team3.name} signed up for topic '#{topics[2].topic_name}' WITHOUT advertisement"
end

# Add one more team on waitlist for Topic 1 WITH advertisement
if user2 && team2
  # Create another team for demonstration
  team4 = AssignmentTeam.find_or_create_by!(
    name: "Team Delta",
    parent_id: assignment.id
  ) do |t|
    t.type = "AssignmentTeam"
  end
  
  # Sign up on waitlist with advertisement
  SignedUpTeam.find_or_create_by!(
    team_id: team4.id,
    project_topic_id: topics[0].id
  ) do |sut|
    sut.is_waitlisted = true
    sut.preference_priority_number = 2
    sut.advertise_for_partner = true
    sut.comments_for_advertisement = "Waitlisted but ready to go! Full-stack team looking to collaborate. We're organized and committed!"
  end
  puts "Team #{team4.name} signed up for topic '#{topics[0].topic_name}' on WAITLIST WITH advertisement"
end

puts "\n" + "="*80
puts "TEST DATA SUMMARY"
puts "="*80
puts "Assignment ID: #{assignment.id}"
puts "Assignment Name: #{assignment.name}"
puts "\nTopics created:"
topics.each do |topic|
  signed_teams = SignedUpTeam.where(project_topic_id: topic.id)
  advertising_teams = signed_teams.where(advertise_for_partner: true)
  puts "  - #{topic.topic_name} (ID: #{topic.id})"
  puts "    Max choosers: #{topic.max_choosers}"
  puts "    Signed up teams: #{signed_teams.count}"
  puts "    Advertising teams: #{advertising_teams.count}"
end

puts "\nTo test the signup sheet, navigate to:"
puts "  http://localhost:3000/assignments/#{assignment.id}/signup_sheet"
puts "\nLogin as: #{user1.name}"
puts "="*80
