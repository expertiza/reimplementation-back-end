# frozen_string_literal: true

class Criterion < ScoredQuestion

  def edit
    edit_html = "<div class=\"question\">"
    edit_html += delete_link(count) + sequence_input(count)
    edit_html += text_area_field + disabled_type_field
    edit_html += weight_input + size_input
    edit_html += labels_input + "</div>"
    edit_html.html_safe
  end

  def view_question_text
    if max_label && min_label
      "<TR><TD align=\"left\">#{txt}</TD><TD align=\"left\">#{formatted_question_type}</TD><td align=\"center\">#{weight}</td><TD align=\"center\">(#{min_label}) 0 to 10 (#{max_label})</TD></TR>"
    else
      "<TR><TD align=\"left\">#{txt}</TD><TD align=\"left\">#{formatted_question_type}</TD><td align=\"center\">#{weight}</td><TD align=\"center\">0 to 10</TD></TR>"
    end
  end

  def complete
    html = "<label>#{txt}</label>"
    html += if dropdown_or_scale == 'dropdown'
              dropdown_options
            else
              scale_options
            end
    html.html_safe
  end

  def advices_criterio_questions
    html = "<ul class=\"advices\">"
    question_advices.each do |advice|
      html << "<li>Advice #{count}: #{advice.txt}</li>"
      count += 1
    end
    html += "</ul>"
    html.html_safe
  end

  def dropdown_criterion_question
    html = "<select>"
    html += "<option value=\"\">Select an option</option>"
    alternatives.split('|').each do |alt|
      selected = (alt == answer) ? 'selected="selected"' : ''
      html += "<option value=\"#{alt}\" #{selected}>#{alt}</option>"
    end
    html += "</select>"
    html.html_safe
  end

  def scale_criterion_question
    html = "<label>#{txt}</label><br>"
    html += "<input type=\"range\" min=\"0\" max=\"10\" value=\"#{answer || 0}\">"
    html.html_safe
  end

  def view_completed_question
    completed_question_html = "<div class=\"question\">"
    completed_question_html += "<div class=\"question-text\">#{txt}</div>"
    completed_question_html += "<div class=\"question-type\">#{formatted_question_type}</div>"
    completed_question_html += "<div class=\"question-weight\">#{weight}</div>"
    completed_question_html += "<div class=\"question-score\">(#{min_label}) #{answer} to #{questionnaire_max} (#{max_label})</div>"
    completed_question_html += "</div>"
    completed_question_html.html_safe
  end




  # Helper methods
  private

  def delete_link(count)
    "<a href=\"javascript:void(0);\" onclick=\"delete_question(#{count})\">delete</a>"
  end

  def sequence_input(count)
    "<input type=\"hidden\" name=\"question[#{count}][sequence]\" value=\"#{seq}\">"
  end

  def text_area_field
    "<textarea name=\"question[#{count}][txt]\">#{txt}</textarea>"
  end

  def disabled_type_field
    "<input type=\"hidden\" name=\"question[#{count}][type]\" value=\"Criterion\" disabled=\"disabled\">"
  end

  def weight_input
    "<input type=\"text\" name=\"question[#{count}][weight]\" value=\"#{weight}\">"
  end

  def size_input
    "<input type=\"text\" name=\"question[#{count}][size]\" value=\"#{size}\">"
  end

  def labels_input
    "<input type=\"text\" name=\"question[#{count}][min_label]\" value=\"#{min_label}\">
     <input type=\"text\" name=\"question[#{count}][max_label]\" value=\"#{max_label}\">"
  end

  def dropdown_options
    html = "<select>"
    html += "<option value=\"\">Select an option</option>"
    alternatives.split('|').each do |alt|
      html << "<option value=\"#{alt}\">#{alt}</option>"
    end
    html += "</select>"
    html.html_safe
  end

  def scale_options
    html = "<label>0</label><input type=\"range\" min=\"0\" max=\"10\" value=\"0\"><label>10</label>"
    html.html_safe
  end
end
