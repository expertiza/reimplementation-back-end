class UploadFile < Question
  # Display the questionnaire editing interface for instructors
  def edit(_count)
    html = <<~HTML
      <tr>
        <td align="center"><a rel="nofollow" data-method="delete" href="/questions/#{id}">Remove</a></td>
        <td><input size="6" value="#{seq}" name="question[#{id}][seq]" id="question_#{id}_seq" type="text"></td>
        <td><textarea cols="50" rows="1" name="question[#{id}][txt]" id="question_#{id}_txt" placeholder="Edit question content here">#{txt}</textarea></td>
        <td><input size="10" disabled="disabled" value="#{type}" name="question[#{id}][type]" id="question_#{id}_type" type="text"></td>
        <td><!-- Placeholder (UploadFile does not need weight) --></td>
      </tr>
    HTML

    html.html_safe
  end

  # Display the questionnaire view interface for instructors
  def view_question_text
    html = <<~HTML
      <tr>
        <td align="left">#{txt}</td>
        <td align="left">#{type}</td>
        <td align="center">#{weight}</td>
        <td align="center">&mdash;</td>
      </tr>
    HTML

    html.html_safe
  end

  # Implement this method for completing a question
  def complete(count, answer = nil)
    # Implement the logic for completing a question
  end

  # Implement this method for viewing a completed question by a student
  def view_completed_question(count, files)
    # Implement the logic for viewing a completed question by a student
  end
end