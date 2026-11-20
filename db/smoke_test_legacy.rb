# frozen_string_literal: true

# No-seed smoke test against the migrated legacy database.
checks = {
  "User" => User,
  "Instructor" => Instructor,
  "Assignment" => Assignment,
  "Course" => Course,
  "Participant" => Participant,
  "AssignmentParticipant" => AssignmentParticipant,
  "Team" => Team,
  "TeamsUser" => TeamsUser,
  "TeamsParticipant" => TeamsParticipant,
  "ProjectTopic" => ProjectTopic,
  "SignedUpTeam" => SignedUpTeam,
  "Questionnaire" => Questionnaire,
  "Item" => Item,
  "Answer" => Answer,
  "QuestionAdvice" => QuestionAdvice,
  "ReviewGrade" => ReviewGrade,
  "ReviewMapping" => ReviewMappingHandler,
  "Role" => Role,
  "Duty" => Duty,
  "DueDate" => DueDate,
  "ResponseMap" => ResponseMap,
  "Response" => Response,
  "JoinTeamRequest" => JoinTeamRequest,
  "Invitation" => Invitation,
  "ScoreView" => ScoreView
}

failures = []
checks.each do |label, klass|
  begin
    if klass <= ActiveRecord::Base
      count = klass.count
      puts "#{label}: #{count} rows OK"
    else
      puts "#{label}: (non-AR class, skipped)"
    end
  rescue StandardError => e
    failures << "#{label}: #{e.class}: #{e.message}"
    puts "FAIL #{label}: #{e.class}: #{e.message}"
  end
end

# Spot-check associations the app depends on.
u = User.first
puts "sample user: username=#{u&.username.inspect} name=#{u&.name.inspect} email=#{u&.email.inspect}"
a = Assignment.first
puts "sample assignment: #{a&.name.inspect} instructor_id=#{a&.instructor_id.inspect} max_team_size=#{a&.max_team_size.inspect}"
i = Item.where(type: 'Criterion').first
puts "sample item: type=#{i&.type.inspect} question_type=#{i&.question_type.inspect} seq=#{i&.seq.inspect}"
t = Team.first
puts "sample team: parent_id=#{t&.parent_id.inspect} type=#{t&.type.inspect}"
d = Duty.first
puts "sample duty: #{d&.name.inspect} instructor_id=#{d&.instructor_id.inspect}"
begin
  q = QuizQuestionnaire.joins(:items).where(items: { question_type: 'Scale' }).first
  sample = q&.items&.first
  ans = sample ? Answer.where(item_id: sample.id).first : nil
  if q && sample && ans
    data = ScoreView.questionnaire_data(q.id, ans.response_id)
    puts "score_views via ScoreView.questionnaire_data: #{data.inspect}"
  else
    puts "score_views: no quiz sample available (skipped)"
  end
rescue StandardError => e
  failures << "ScoreView sample: #{e.class}: #{e.message}"
  puts "FAIL ScoreView sample: #{e.class}: #{e.message}"
end

if failures.empty?
  puts "SMOKE TEST PASSED"
else
  puts "SMOKE TEST FAILURES: #{failures.size}"
  exit 1
end
