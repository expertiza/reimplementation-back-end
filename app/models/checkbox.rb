class Checkbox < UnscoredQuestion
  include ActionView::Helpers

  # This method returns what to display if an instructor (etc.) is creating or editing a questionnaire (questionnaires_controller.rb).
  def edit(count)
    render partial: 'questionnaire/edit/edit_checkbox'
  end

  # This method returns what to display if an instructor (etc.) is viewing a questionnaire
  def view_question_text
    html = "<TR><TD align=\"left\"> #{txt} </TD>"
    html += "<TD align=\"left\">#{type}</TD>"
    html += "<td align=\"center\">#{weight.to_s}</TD>"
    html += '<TD align="center">Checked/Unchecked</TD>'
    html += '</TR>'
    safe_join([''.html_safe, ''.html_safe], html.html_safe)
  end

  # Returns what to display for the complete checkbox question.
  def complete(count, answer = nil)
    html = check_previous_question + complete_first_second_input(count, answer)
    html += complete_third_input(count, answer)
    html += "<label for=\"responses_#{count.to_s}\">&nbsp;&nbsp;#{txt}</label>"
    html += complete_script(count)
    html += complete_if_header
    safe_join([''.html_safe, ''.html_safe], html.html_safe)
  end

  # This method checks if the previous question is a ColumnHeader and returns a beginning table data cell tag if it is.
  def check_previous_question
    curr_question = Question.find(id)
    prev_question = Question.where('seq < ?', curr_question.seq).order(:seq).last
    if prev_question.type == 'ColumnHeader'
      '<td style="padding: 15px;">'
    else
      ''
    end
  end

  # Returns what to display for the first and second inputs (comments and scores).
  def complete_first_second_input(count, answer = nil)
    html = "<input id=\"responses_#{count.to_s}_comments\" name=\"responses[#{count.to_s}][comment]\" type=\"hidden\" value=\"\">"
    html += "<input id=\"responses_#{count.to_s}_score\" name=\"responses[#{count.to_s}][score]\" type=\"hidden\""
    html += if !answer.nil? && (answer.answer == 1)
              'value="1"'
            else
              'value="0"'
            end
    html += '>'
    html
  end

  # Returns what to display for the third input (the checkbox itself).
  def complete_third_input(count, answer = nil)
    html = "<input id=\"responses_#{count.to_s}_checkbox\" type=\"checkbox\" onchange=\"checkbox#{count.to_s}Changed()\""
    html += 'checked="checked"' if !answer.nil? && (answer.answer == 1)
    html += '>'

    html
  end

  # Create the executable script for client-side interaction on the checkbox
  def complete_script(count)
    html = "<script>function checkbox#{count.to_s}Changed() {"
    html += " var checkbox = jQuery(\"#responses_#{count.to_s}_checkbox\");"
    html += " var response_score = jQuery(\"#responses_#{count.to_s}_score\");"
    html += 'if (checkbox.is(":checked")) {'
    html += 'response_score.val("1");'
    html += '} else {'
    html += 'response_score.val("0");}}</script>'
    html
  end

  # If the next question is a ColumnHeader, SectionHeader or a TableHeader, return the closing tags for the table/table row/data cell.
  def complete_if_header
    curr_question = Question.find(id)
    next_question = Question.where('seq > ?', curr_question.seq).order(:seq).first
    case next_question.type
    when 'ColumnHeader'
      '</td></tr>'
    when 'SectionHeader', 'TableHeader'
      '</td></tr></table><br/>'
    else
      '<BR/>'
    end
  end

  # Returns what to display if a student is viewing a filled-out questionnaire.
  def view_completed_question(count, answer)
    html = check_previous_question
    html += view_completed_question_answer(count, answer)
    html += view_completed_question_if_header
    safe_join([''.html_safe, ''.html_safe], html.html_safe)
  end

  # Returns the question and answer portion of the filled-out questionnaire.
  def view_completed_question_answer(count, answer)
    if answer.answer == 1
      "<b>#{count.to_s}. &nbsp;&nbsp;<img src=\"/assets/Check-icon.png\">#{txt}</b>"
    else
      "<b>#{count.to_s}. &nbsp;&nbsp;<img src=\"/assets/delete_icon.png\">#{txt}</b>"
    end
  end

  # Returns what to display for the column header, section header or table header portion of the filled-out questionnaire.
  def view_completed_question_if_header
    curr_question = Question.find(id)
    next_question = Question.where('seq > ?', curr_question.seq).order(:seq).first
    case next_question.type
    when 'ColumnHeader'
      '</td></tr>'
    when 'TableHeader'
      '</td></tr></table>'
    else
      ''
    end
  end

end
