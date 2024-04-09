# Inherits from ScoredQuestion, representing a question type with a scoring criterion
class Criterion < ScoredQuestion
  # Ensure the presence of the size attribute for a Criterion instance
  validates :size, presence: true

  # Method to construct the structure needed for editing a criterion question
  def edit
    {
      remove_link: "/questions/#{id}",  # Link to remove the question
      sequence_input: seq.to_s,  # The sequence number of the question as a string
      question_text: txt,  # The text content of the question
      question_type: question_type,  # The type of the question, e.g., 'Criterion'
      weight: weight.to_s,  # The weight of the question as a string
      size: size.to_s,  # The size attribute of the criterion question as a string
      max_label: max_label,  # The label for the maximum score
      min_label: min_label  # The label for the minimum score
    }
  end

  # Method to construct the structure needed for viewing the text of a criterion question
  def view_question_text
    question_data = {
      text: txt,  # The text content of the question
      question_type: question_type,  # The type of the question
      weight: weight,  # The weight of the question
      score_range: "#{questionnaire.min_question_score} to #{questionnaire.max_question_score}"  # The score range from the associated questionnaire
    }

    # Append min and max labels to the score range if they are present
    if max_label && min_label
      question_data[:score_range] = "(#{min_label}) " + question_data[:score_range] + " (#{max_label})"
    end

    question_data
  end

  # Method to construct the response structure for a criterion question
  def complete(count, answer = nil, questionnaire_min, questionnaire_max, dropdown_or_scale)
    # Retrieve advices for the question and calculate their total length
    question_advices = QuestionAdvice.to_json_by_question_id(id)
    advice_total_length = question_advices.sum { |advice| advice.advice.length unless advice.advice.blank? }

    # Determine the response options based on whether it's a dropdown or scale type
    response_options = if dropdown_or_scale == 'dropdown'
                         dropdown_criterion_question(count, answer, questionnaire_min, questionnaire_max)
                       elsif dropdown_or_scale == 'scale'
                         scale_criterion_question(count, answer, questionnaire_min, questionnaire_max)
                       end

    # Construct the advice section if there are any advices
    advice_section = question_advices.empty? || advice_total_length.zero? ? nil : advices_criterion_question(count, question_advices)

    # Construct and return the final structure, removing any nil values with .compact
    {
      label: txt,  # The text of the question
      advice: advice_section,  # The advice section, if applicable
      response_options: response_options  # The response options for the question
    }.compact
  end

  # Method to generate dropdown options for a criterion question
  def dropdown_criterion_question(count, answer, questionnaire_min, questionnaire_max)
    # Generate a list of options based on the min and max scores from the questionnaire
    options = (questionnaire_min..questionnaire_max).map do |score|
      option = { value: score, label: score.to_s }  # Each option has a value and label
      option[:selected] = 'selected' if answer && score == answer.answer  # Mark the option as selected if it matches the answer
      option
    end
    # Return the structure for a dropdown criterion question
    { type: 'dropdown', options: options, current_answer: answer.try(:answer), comments: answer.try(:comments) }
  end

  # Method to generate scale options for a criterion question
  def scale_criterion_question(count, answer, questionnaire_min, questionnaire_max)
    # Return the structure for a scale criterion question
    {
      type: 'scale',
      min: questionnaire_min,  # Minimum score
      max: questionnaire_max,  # Maximum score
      current_answer: answer.try(:answer),  # Current answer if available
      comments: answer.try(:comments),  # Any comments on the answer
      min_label: min_label,  # Label for the minimum score
      max_label: max_label,  # Label for the maximum score
      size: size  # Size of the scale
    }
  end

  private

  # Method to structure advices for a criterion question
  def advices_criterion_question(question_advices)
    # Map each advice to a structure containing its score and advice content
    question_advices.map do |advice|
      {
        score: advice.score,  # The score associated with the advice
        advice: advice.advice  # The advice content
      }
    end
  end
end