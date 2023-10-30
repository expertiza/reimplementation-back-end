class TextField < TextResponse
  # TextField class is for text questions that are only 1 line

  # This method decides what to display when a user is viewing a filled-out questionnaire
  def complete(count, answer = nil)
    html = '<p style="width: 80%;">'
    html += '<label for="responses_' + count.to_s + '">' + txt + '&nbsp;&nbsp;</label>'
    html += '<input id="responses_' + count.to_s + '_score" name="responses[' + count.to_s + '][score]" type="hidden" value="">'
    html += '<input id="responses_' + count.to_s + '_comments" label="' + txt + '" name="responses[' + count.to_s + '][comment]" style="width: 40%;" size="' + size.to_s + '" type="text"'
    html += 'value="' + answer.comments.to_s unless answer.nil?
    html += '">'
    html += '<br><br>' if type == 'TextField' && !break_before
    html.html_safe
  end

  # This method decides what to display when a user is filling out a questionnaire
  def view_completed_question(count, answer)
    if type == 'TextField' && break_before
      html = "<b>#{count}. #{txt}</b>&nbsp;&nbsp;&nbsp;&nbsp;#{answer.comments}"
      html += '<br><br>' if next_question_has_break?(answer.question_id)
    else
      html = "#{txt}#{answer.comments}<br><br>"
    end
    html.html_safe
  end

  private

  def next_question_has_break?(question_id)
    next_question = Question.find_by(id: question_id + 1)
    next_question&.break_before
  end
end
