class TrueFalse < QuizQuestion

  # return HTML shown to admins when editing multiple choice radio
  # extends the html prefix from QuizQuestion and displays two choices as true/false radio selection
  def edit
    html = super

    html += '<tr><td>'
    html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][TrueFalse][1][iscorrect]" '
    html += 'id="quiz_question_choices_' + id.to_s + '_TrueFalse_1_iscorrect_True" value="True" '
    html += 'checked="checked" ' if self.quiz_question_choices[0].iscorrect
    html += '/>True'
    html += '</td></tr>'

    html += '<tr><td>'
    html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][TrueFalse][1][iscorrect]" '
    html += 'id="quiz_question_choices_' + id.to_s + '_TrueFalse_1_iscorrect_True" value="False" '
    html += 'checked="checked" ' if self.quiz_question_choices[1].iscorrect
    html += '/>False'
    html += '</td></tr>'

    html.html_safe
  end

  def complete
    quiz_question_choices = self.quiz_question_choices
    html = '<label for="' + id.to_s + '">' + txt + '</label><br>'
    (0..1).each do |i|
      html += '<input name = ' + "\"#{id}\" "
      html += 'id = ' + "\"#{id}" + '_' + "#{i + 1}\" "
      html += 'value = ' + "\"#{quiz_question_choices[i].txt}\" "
      html += 'type="radio"/>'
      html += if i == 0
                'True'
              else
                'False'
              end
      html += '</br>'
    end
    html
  end

  def view_completed_question(user_answer)
    quiz_question_choices = self.quiz_question_choices
    html = ''
    html += 'Correct Answer is: <b>'
    html += if quiz_question_choices[0].iscorrect
              'True</b><br/>'
            else
              'False</b><br/>'
            end
    html += 'Your answer is: <b>' + user_answer.first.comments.to_s
    html += if user_answer.first.answer == 1
              '<img src="/assets/Check-icon.png"/>'
            else
              '<img src="/assets/delete_icon.png"/>'
            end

    html += '</b>'
    html += '<br><br><hr>'
    html.html_safe
    # html += 'i += 1'
  end
end
