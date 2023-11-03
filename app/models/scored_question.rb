# frozen_string_literal: true

class ScoredQuestion < ChoiceQuestion

  self.table_name = 'questions'
  def scorable?
    true
  end

  ##############

  def edit
    html = '<div>'
    html += "<label for='question_#{id}'>Question #{count}:</label>"
    html += "<input type='text' id='question_#{id}' name='question[#{id}]' value='#{txt}' />"
    html += "<input type='number' name='weight[#{id}]' value='#{weight}' />"
    html += '</div>'
    html
  end

  def view_question_text

  end

  def compute
    score = (weight.to_i * 2) # Adjust your scoring logic here
    "Score: #{score}"
  end

  def view_completed_question
    result = "Question #{count}: #{txt}"
    result += "<p>Answer: #{answer}</p>" unless answer.nil?
    result += "<p>Score: #{compute}</p>"
    result
  end

  def self.compute_question_score
    # Compute scored question score logic
  end
end
