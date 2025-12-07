# Script to debug score calculation
assignment = Assignment.first
puts "Assignment: #{assignment.name} (ID: #{assignment.id})"

# Get the first review response map
map = ReviewResponseMap.where(reviewed_object_id: assignment.id).first
puts "Map ID: #{map.id}"

# Get the response
response = Response.where(map_id: map.id).order(created_at: :desc).first
puts "Response ID: #{response.id}"

# Check scores (Answers)
scores = response.scores
puts "Scores count: #{scores.count}"

scores.each do |s|
  item = Item.find_by(id: s.question_id)
  if item
    puts "  Answer: #{s.answer}, Question ID: #{s.question_id}, Item Type: #{item.question_type}, Weight: #{item.weight}, Scorable: #{item.scorable?}"
  else
    puts "  Answer: #{s.answer}, Question ID: #{s.question_id} - ITEM NOT FOUND"
  end
end

# Calculate score manually
sum = 0
scores.each do |s|
  item = Item.find_by(id: s.question_id)
  if item && !s.answer.nil? && item.scorable?
    puts "    Adding #{s.answer} * #{item.weight} = #{s.answer * item.weight}"
    sum += s.answer * item.weight
  else
    puts "    Skipping: Answer nil? #{s.answer.nil?}, Item found? #{!item.nil?}, Scorable? #{item&.scorable?}"
  end
end
puts "Manual Sum: #{sum}"

# Call the method
puts "Method Result: #{response.aggregate_questionnaire_score}"
