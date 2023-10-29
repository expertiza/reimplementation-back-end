class MultipleChoiceRadio < QuizQuestion
  # Override the edit method for MultipleChoiceRadio
  def edit
    # Provide your custom implementation here, e.g., render a specific partial template
    render partial: '_edit_multi_radio'
  end

  # Override the complete method for MultipleChoiceRadio
  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    html = "<label for=\"#{id.to_s}\">#{txt}</label><br>"

    # Customize the display for multiple choice radio questions
    quiz_question_choices.each_with_index do |choice, index|
      html += "<input name=\"#{id}\" "
      html += "id=\"#{id}_#{index + 1}\" "
      html += "value=\"#{choice.txt}\" "
      html += 'type="radio"/>'
      html += choice.txt.to_s
      html += '</br>'
    end
    html.html_safe
  end

  # Override the view_completed_question method for MultipleChoiceRadio
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

    html += '<br>Your answer is: '
    html += "<b>#{user_answer.first.comments.to_s}</b>"

    html += if user_answer.first.answer == 1
              '<img src="/assets/Check-icon.png"/>'
            else
              '<img src="/assets/delete_icon.png"/>'
            end

    html += '</b>'
    html += '<br><br><hr>'
    html.html_safe
  end

  # Override the is_valid method for MultipleChoiceRadio
  def is_valid(choice_info)
    valid = 'Valid'
    valid = 'Please make sure all questions have text.' if txt.blank?
    correct_count = 0
    choice_info.each_value do |value|
      if value[:txt].blank?
        valid = 'Please make sure every question has text for all options.'
        break
      end
      correct_count += 1 if value[:correct] == '1'
    end

    valid = 'Please select a correct answer for all questions.' if correct_count.zero?
    valid
  end
end