class MultipleChoiceRadio < QuizQuestion
  def edit
    {
      id: id,
      txt: txt,
      question_type: question_type
    }.to_json
  end

  def complete
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)
    choices = []

    quiz_question_choices.each_with_index do |choice, index|
      choices << {
        name: id.to_s,
        id: "#{id}_#{index + 1}",
        value: choice.txt,
        type: 'radio'
      }
    end

    {
      label: txt,
      choices: choices
    }.to_json
  end

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
      answer: user_answer.first.answer == 1 ? '<img src="/assets/Check-icon.png"/>' : '<img src="/assets/delete_icon.png"/>',
      comments: [user_answer.first.comments.to_s]
    }

    {
      answers: answers,
      user_answer: user_answer_info
    }.to_json
  end

  def is_valid(choice_info)
    valid = 'Valid'
    correct_count = 0

    choice_info.each_value do |value|
      if value[:txt].blank?
        valid = 'Please make sure every question has text for all options.'
        break
      end
      correct_count += 1 if value[:correct]
    end

    valid = 'Please select a correct answer for all questions.' if correct_count.zero?
    valid = 'Please select only one correct answer.' if correct_count > 1

    valid
  end
end
