class MultipleChoiceCheckbox < QuizQuestion

  # This method returns what to display if an instructor (etc.) is creating or editing a questionnaire (questionnaires_controller.rb).
  def edit
    render partial: 'questionnaire/edit/edit_multi_checkbox'
  end

  # Returns what to display for the complete multiple choice checkbox question.
  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    html = "<label for=\"#{id.to_s}\">#{txt}</label><br>"
    # There are four answer choices
    [0, 1, 2, 3].each do |i|
      html += "<input name = \"#{id}[]\" "
      html += "id = \"#{id}_#{i + 1}\" "
      html += "value = \"#{quiz_question_choices[i].txt}\" "
      html += 'type="checkbox"/>'
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
      html += "<b>#{answer.txt}</b> -- Correct <br>" if answer.correct
    end
    html += '<br>Your answer is:'
    html += if user_answer[0].answer == 1
              '<img src="/assets/Check-icon.png"/><br>'
            else
              '<img src="/assets/delete_icon.png"/><br>'
            end
    user_answer.each do |answer|
      html += "<b>#{answer.comments.to_s}</b><br>"
    end
    html += '<br><hr>'
    html.html_safe
  end

  # Returns a "Valid" message or error messages depending on if the question has valid inputs.
  def is_valid(choice_info)
    valid = 'Valid'
    valid = 'Please make sure all questions have text.' if txt == ''
    correct_count = 0
    choice_info.each_value do |value|
      if value[:txt] == ''
        valid = 'Please make sure every question has text for all options.'
        break
      end
      correct_count += 1 if value[:correct] == 1.to_s
    end
    if correct_count.zero?
      valid = 'Please select a correct answer for all questions.'
    elsif correct_count == 1
      valid = 'A multiple-choice checkbox question should have more than one correct answer.'
    end
    valid
  end
end
