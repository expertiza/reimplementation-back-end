class TextArea < TextResponse
  attr_accessor :type
  # TextArea class is for text questions that have a height and width sized textbox (Adjustable)

  # This method decides what to display while a user is viewing a filled out questionnaire
  def complete(count, answer = nil)
    cols, rows = size ? size.split(',') : ['70', '1']

    {
      question_id: id,
      type: type,
      cols: cols.to_i,
      rows: rows.to_i,
      count: count
    }.to_json
  end

  # This method decides what to display while a user is filling out a questionnaire
  def view_completed_question(count, answer)
    cleaned_comments = answer.comments.to_s.gsub('^p', '').gsub(/\n/, '<BR/>')

    {
      question_id: id,
      type: type,
      comments: cleaned_comments,
      count: count
    }.to_json
  end
end
