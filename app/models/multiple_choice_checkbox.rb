class MultipleChoiceCheckbox < QuizQuestion
  # Override the edit method for MultipleChoiceCheckbox
  def edit
    # Provide your custom implementation here, e.g., render a specific partial template
    render partial: '_edit_multi_checkbox'
  end

  # Override the complete method for MultipleChoiceCheckbox
  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    html = "<label for=\"#{id.to_s}\">#{txt}</label><br>"

    # Customize the display for multiple choice checkbox questions
    quiz_question_choices.each_with_index do |choice, index|
      html += "<input name=\"#{id}[]\" "
      html += "id=\"#{id}_#{index + 1}\" "
      html += "value=\"#{choice.txt}\" "
      html += 'type="checkbox"/>'
      html += choice.txt.to_s
      html += '</br>'
    end
    html.html_safe
  end

  # Override the view_completed_question method for MultipleChoiceCheckbox
  def view_completed_question(user_answer)
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    html = ''

    quiz_question_choices.each do |answer|
      html += if answer.correct
                "<b>#{answer.txt}</b> -- Correct <br>"
              else
                "#{answer.txt} <br>"
              end
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

  # Override the is_valid method for MultipleChoiceCheckbox
  def is_valid(choice_info)
    valid = 'Valid'
    #valid = 'Please make sure all questions have text.' if txt.blank?
    correct_count = 0

    choice_info.each_value do |value|
      if value[:txt].blank?
        valid = 'Please make sure every option has text for all options.'
        break
      end

      # Check if the 'correct' attribute is truthy (not nil or false)
      if value[:correct]
        correct_count += 1
      end
    end

    if correct_count.zero?
      valid = 'Please select a correct answer for all questions.'
    elsif correct_count == 1
      valid = 'A multiple-choice checkbox question should have more than one correct answer.'
    end

    valid
  end

end