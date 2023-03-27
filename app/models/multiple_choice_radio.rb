class MultipleChoiceRadio < QuizQuestion

  # return HTML shown to admins when editing multiple choice radio
  # extends the html prefix from QuizQuestion and displays four choices a radio selection
  def edit
    html = super

    # for i in 0..3
    [0, 1, 2, 3].each do |i|
      html += '<tr><td>'

      html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceRadio][correctindex]" '
      html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceRadio_correctindex_' + (i + 1).to_s + '" value="' + (i + 1).to_s + '" '
      html += 'checked="checked" ' if self.quiz_question_choices[i].iscorrect
      html += '/>'

      html += '<input type="text" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceRadio][' + (i + 1).to_s + '][txt]" '
      html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceRadio_' + (i + 1).to_s + '_txt" '
      html += 'value="' + self.quiz_question_choices[i].txt + '" size="40" />'

      html += '</td></tr>'
    end

    html.html_safe
    # safe_join(html)
  end

end
