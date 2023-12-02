# frozen_string_literal: true

class Criterion < ScoredQuestion
  attr_accessor :formatted_question_type

  def edit(count)
    {
      question_id: id,
      delete_link: delete_link(count),
      sequence_input: sequence_input(count),
      text_area_field: text_area_field(count),
      disabled_type_field: disabled_type_field,
      weight_input: weight_input(count),
      size_input: size_input(count),
      labels_input: labels_input(count)
    }.to_json
  end

  def view_question_text
    {
      formatted_text: formatted_text,
      type: formatted_question_type,
      weight: weight,
      score_range: score_range
    }.to_json
  end

  def complete(dropdown_or_scale)
    options = dropdown_or_scale == 'dropdown' ? dropdown_options : scale_options
    { label: txt, options: options }.to_json
  end

  def advices_criterion_question(count)
    advices = question_advices.map { |advice| { advice_count: count, advice_text: advice.txt } }
    { advices: advices }.to_json
  end

  def dropdown_criterion_question(answer)
    options = alternatives.split('|').map { |alt| { value: alt, selected: (alt == answer) } }
    { dropdown_options: options }.to_json
  end

  def scale_criterion_question
    { label: txt, range: { min: 0, max: 10, value: answer || 0 } }.to_json
  end

  def view_completed_question(count, answer, questionnaire_max)
    {
      question: formatted_text,
      type: formatted_question_type,
      weight: weight,
      score: "(#{min_label}) #{answer} to #{questionnaire_max} (#{max_label})"
    }.to_json
  end

  private

  def formatted_text
    "<div class=\"question\">#{delete_link(count)}#{sequence_input(count)}"\
      "#{text_area_field(count)}#{disabled_type_field}#{weight_input(count)}#{size_input(count)}#{labels_input(count)}</div>".html_safe
  end

  def delete_link(count)
    "<a href=\"javascript:void(0);\" onclick=\"delete_question(#{count})\">delete</a>"
  end

  def sequence_input(count)
    "<input type=\"hidden\" name=\"question[#{count}][sequence]\" value=\"#{seq}\">"
  end

  def text_area_field(count)
    "<textarea name=\"question[#{count}][txt]\">#{txt}</textarea>"
  end

  def disabled_type_field
    "<input type=\"hidden\" name=\"question[#{count}][type]\" value=\"Criterion\" disabled=\"disabled\">"
  end

  def weight_input(count)
    "<input type=\"text\" name=\"question[#{count}][weight]\" value=\"#{weight}\">"
  end

  def size_input(count)
    "<input type=\"text\" name=\"question[#{count}][size]\" value=\"#{size}\">"
  end

  def labels_input(count)
    "<input type=\"text\" name=\"question[#{count}][min_label]\" value=\"#{min_label}\">"\
      "<input type=\"text\" name=\"question[#{count}][max_label]\" value=\"#{max_label}\">"
  end

  def score_range
    max_label && min_label ? "(#{min_label}) 0 to 10 (#{max_label})" : '0 to 10'
  end

  def dropdown_options
    options = alternatives.split('|').map { |alt| { value: alt } }
    { dropdown_options: options }.to_json
  end

  def scale_options
    { range: { min: 0, max: 10, value: 0 } }.to_json
  end
end