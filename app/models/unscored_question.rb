# frozen_string_literal: true

class UnscoredQuestion < ChoiceQuestion

  self.table_name = 'questions'

  def edit
    html = '<div>'
    html += "<label for='question_#{id}'>Question #{count}:</label>"
    html += "<input type='text' id='question_#{id}' name='question[#{id}]' value='#{txt}' />"
    html += '</div>'
    html
  end

  def view_question_text
    "<p>#{txt}</p>"
  end

  def compute
    # Compute unscored question logic
  end

  def view_completed_question
    result = "Question #{count}: #{txt}"
    result += "<p>Answer: #{answer}</p>" unless answer.nil?
    result
  end
end
