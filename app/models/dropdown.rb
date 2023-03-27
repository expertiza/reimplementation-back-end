class Dropdown < UnscoredQuestion
  include ActionView::Helpers
  validates :alternatives, presence: true

  def edit(_count)
    render partial: 'questionnaire/edit/edit_dropdown'
  end

  def view_question_text
    html = "<TD align=\"left\"> #{txt} </TD>"
    html += "<TD align=\"left\">#{type}</TD>"
    html += "<td align=\"center\">#{weight.to_s}</TD><TD align=\"center\">&mdash;</TD>"

    safe_join(['<TR>'.html_safe, '</TR>'.html_safe], html.html_safe)
  end

  def complete(count, answer = nil)
    html = "<p style=\"width: 80%;\"><label for=\"responses_#{count.to_s}\"\">#{txt}&nbsp;&nbsp;</label>"
    html += "<input id=\"responses_#{count.to_s}_score\" name=\"responses[#{count.to_s}][score]\" type=\"hidden\" value=\"\" style=\"min-width: 100px;\">"
    html += "<select id=\"responses_#{count.to_s}_comments\" label=#{txt} name=\"responses[#{count.to_s}][comment]\">"

    alternatives = self.alternatives.split('|')
    html += complete_for_alternatives(alternatives, answer)
    html += '</select></p>'
    html.html_safe
  end

  def complete_for_alternatives(alternatives, answer)
    html = ''
    alternatives.each do |alternative|
      html += "<option value=\"#{alternative.to_s}\""
      html += ' selected' if !answer.nil? && (answer.comments == alternative)
      html += ">#{alternative.to_s}</option>"
    end
    html
  end

  def view_completed_question(count, answer)
    html = "<b>#{count.to_s}. #{txt}</b>"
    html += "<BR>&nbsp&nbsp&nbsp&nbsp#{answer.comments.to_s}"

    safe_join([''.html_safe, ''.html_safe], html.html_safe)
  end
end
