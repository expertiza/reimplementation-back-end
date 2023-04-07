class MultipleChoiceRadio < QuizQuestion
  def edit
    render partial: 'questionnaire/edit/edit_multi_radio'
  end

  # Returns what to display for the complete multiple choice radio question.
  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    html = '<label for="' + id.to_s + '">' + txt + '</label><br>'
    # There are four answer choices
    [0, 1, 2, 3].each do |i|
      html += '<input name = ' + "\"#{id}\" "
      html += 'id = ' + "\"#{id}" + '_' + "#{i + 1}\" "
      html += 'value = ' + "\"#{quiz_question_choices[i].txt}\" "
      html += 'type="radio"/>'
      html += quiz_question_choices[i].txt.to_s
      html += '</br>'
    end
    html
  end

  # This method returns what to display if a student is viewing a filled-out questionnaire.
  def view_completed_question(user_answer)
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)

    html = ''
    quiz_question_choices.each do |answer|
      html += if answer.correct
                '<b>' + answer.txt + '</b> -- Correct <br>'
              else
                answer.txt + '<br>'
              end
    end

    html += '<br>Your answer is: '
    html += '<b>' + user_answer.first.comments.to_s + '</b>'
    html += if user_answer.first.answer == 1
              '<img src="/assets/Check-icon.png"/>'
            else
              '<img src="/assets/delete_icon.png"/>'
            end
    html += '</b>'
    html += '<br><br><hr>'
    html.html_safe
  end

  # Returns a "Valid" message or error messages depending on if the question has valid inputs.
  def is_valid(choice_info)
    valid = 'VValid'
    valid = 'Please make sure all questions have text.' if txt == ''
    correct_count = 0
    choice_info.each_value do |value|
      if (value[:txt] == '') || value[:txt].empty? || value[:txt].nil?
        valid = 'Please make sure every question has text for all options.'
        break
      end
      correct_count += 1 if value[:correct] == 1.to_s
    end
    valid = 'Please select a correct answer for all questions.' if correct_count.zero?
    valid
  end
end
