class QuizQuestion < Question
  has_many :quiz_question_choices, class_name: 'QuizQuestionChoice', foreign_key: 'question_id', inverse_of: false, dependent: :nullify
  def edit; end

  def view_question_text
    html = '<b>' + txt + '</b><br />'
    html += 'Question Type: ' + type + '<br />'
    html += 'Question Weight: ' + weight.to_s + '<br />'
    if quiz_question_choices
      quiz_question_choices.each do |choices|
        html += if choices.iscorrect?
                  '  - <b>' + choices.txt + '</b><br /> '
                else
                  '  - ' + choices.txt + '<br /> '
                end
      end
      html += '<br />'
    end
    html.html_safe
  end

def complete
    quiz_question_choices = self.quiz_question_choices
    html = '<label for="' + id.to_s + '">' + txt + '</label><br>'
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

  def view_completed_question(user_answer)
    quiz_question_choices = self.quiz_question_choices

    html = ''
    quiz_question_choices.each do |answer|
      html += if answer.iscorrect
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

  def isvalid(choice_info)
    @valid = 'valid'
    return @valid = 'Please make sure all questions have text' if txt == ''
    @correct_count = 0
    choice_info.each_value do |value|
      if (value[:txt] == '') || value[:txt].empty? || value[:txt].nil?
        @valid = 'Please make sure every question has text for all options'
        return @valid
      end
      @correct_count += 1 if value.key?(:iscorrect)
    end
    @valid = 'Please select a correct answer for all questions' if @correct_count.zero?
    @valid
  end
end
