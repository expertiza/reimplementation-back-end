class QuizQuestion < Question
  has_many :quiz_question_choices, class_name: 'QuizQuestionChoice', foreign_key: 'question_id', inverse_of: false, dependent: :nullify

  # This method returns what to display if an instructor (etc.) is creating or editing a questionnaire (questionnaires_controller.rb).
  def edit; end

  # This method returns what to display if an instructor (etc.) is viewing a questionnaire
  def view_question_text
    html = '<b>' + txt + '</b><br />'
    html += 'Question Type: ' + type + '<br />'
    html += 'Question Weight: ' + weight.to_s + '<br />'
    if quiz_question_choices
      quiz_question_choices.each do |choices|
        html += if choices.correct?
                  '  - <b>' + choices.txt + '</b><br /> '
                else
                  '  - ' + choices.txt + '<br /> '
                end
      end
      html += '<br />'
    end
    html.html_safe
  end

  # Returns what to display for the complete question.
  def complete; end

  # Returns what to display if a student is viewing a filled-out questionnaire.
  def view_completed_question; end
end
