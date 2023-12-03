class TextField < TextResponse
  attr_accessor :type
  # TextField class is for text questions that are only 1 line

  # This method decides what to display when a user is viewing a filled-out questionnaire
  def complete(count, answer = nil)
    {
      question_id: id,
      type: type,
      count: count,
      answer: answer.to_s,
    }.to_json
  end

  # This method decides what to display when a user is filling out a questionnaire
  def view_completed_question(count, answer)
    {
      question_id: id,
      type: type,
      count: count,
      comments: answer.comments,
      has_break: next_question_has_break?(answer.question_id),
    }.to_json
  end

  private

  def next_question_has_break?(question_id)
    next_question = Question.find_by(id: question_id + 1)
    next_question && next_question.break_before || false
  end
end
