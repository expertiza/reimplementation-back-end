class MultipleChoiceCheckbox < QuizQuestion
  # Override the edit method for MultipleChoiceCheckbox
  def edit
    {
      id: id,
      txt: txt,
      question_type: question_type,
    }.to_json
  end

  # Override the complete method for MultipleChoiceCheckbox
  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    choices = []

    quiz_question_choices.each_with_index do |choice, index|
      choices << {
        name: id.to_s,
        id: "#{id}_#{index + 1}",
        value: choice.txt,
        type: 'checkbox'
      }
    end

    {
      label: txt,
      choices: choices
    }.to_json
  end

  # Override the view_completed_question method for MultipleChoiceCheckbox
  def view_completed_question(user_answer)
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    answers = []

    quiz_question_choices.each do |answer|
      if answer.correct
        answers << {
          text: answer.txt,
          correctness: 'Correct'
        }
      else
        answers << {
          text: answer.txt
        }
      end
    end

    user_answer_info = {
      answer: user_answer[0].answer == 1 ? '<img src="/assets/Check-icon.png"/>' : '<img src="/assets/delete_icon.png"/>',
      comments: user_answer.map { |ans| ans.comments.to_s }
    }

    {
      answers: answers,
      user_answer: user_answer_info
    }.to_json
  end

  # Override the is_valid method for MultipleChoiceCheckbox
  def is_valid(choice_info)
    valid = 'Valid'
    correct_count = 0

    choice_info.each_value do |value|
      if value[:txt].blank?
        valid = 'Please make sure every option has text for all options.'
        break
      end

      correct_count += 1 if value[:correct]
    end

    if correct_count.zero?
      valid = 'Please select a correct answer for all questions.'
    elsif correct_count == 1
      valid = 'A multiple-choice checkbox question should have more than one correct answer.'
    end

    valid
  end
end
