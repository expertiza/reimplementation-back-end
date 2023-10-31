# frozen_string_literal: true

class Dropdown < UnscoredQuestion

  def edit(count)
    html = '<div>'
    html += "<label for='question_#{id}'>Question #{count}:</label>"
    html += "<input type='text' id='question_#{id}' name='question[#{id}]' value='#{txt}' />"
    html += '</div>'
    html
  end

  def view_question_text
    if txt.nil? || type.nil? || weight.nil?
      'Invalid input values'
    end

    html = "<TR><TD align='left'> #{txt} </TD><TD align='left'>#{type}</TD><td align='center'>#{weight}</TD><TD align='center'>&mdash;</TD></TR>"
    html
  end

  def complete(count, answer = nil)    #initial ans = nil
    html = ''
    html += '<select>'
    if count
      (1..count).each do |option|
        selected = (option == answer.to_i) ? 'selected' : ''
        html += "<option value='#{option}' #{selected}>#{option}</option>"
      end
    end
    html += '</select>'
    html
  end

  def complete_for_alternatives(alternatives, answer)
    html = '<select>'
    alternatives.each do |option|
      selected = (option == answer) ? 'selected' : ''
      html += "<option value='#{option}' #{selected}>#{option}</option>"
    end
    html += '</select>'
    html
  end

  def view_completed_question
    html = ''
    if count && answer
      html = "Selected option: #{answer} (out of #{count})"
    else
      html = "Question not answered."
    end
    return html
  end
end
