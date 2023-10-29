class TextArea < TextResponse
  # TextArea class is for text questions that have a height and width sized textbox (Adjustable)

  # This method decides what to display while a user is viewing a filled out questionnaire
  def complete(count, answer = nil)
    cols, rows = size ? size.split(',') : ['70', '1']

    html = <<~HTML
      <p><label for="responses_#{count}">#{txt}</label></p>
      <input id="responses_#{count}_score" name="responses[#{count}][score]" type="hidden" value="">
      <p><textarea cols="#{cols}" rows="#{rows}" id="responses_#{count}_comments" name="responses[#{count}][comment]" class="tinymce">
        #{answer.comments if answer}
      </textarea></p>
    HTML

    html.html_safe
  end

  # This method decides what to display while a user is filling out a questionnaire
  def view_completed_question(count, answer)
    cleaned_comments = answer.comments.to_s.gsub('^p', '').gsub(/\n/, '<BR/>')

    html = <<~HTML
      <b>#{count}. #{txt}</b><BR/>
      #{'&nbsp;' * 8}#{cleaned_comments}<BR/><BR/>
    HTML

    html.html_safe
  end
end
