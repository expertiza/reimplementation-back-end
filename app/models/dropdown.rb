# Inherits from UnscoredQuestion and includes QuestionHelper to utilize common functionality
class Dropdown < UnscoredQuestion
  include QuestionHelper

  # Define accessible attributes for instances of Dropdown
  attr_accessor :txt, :type, :count, :weight
  
  # Method to prepare and return the JSON structure for editing a dropdown question
  def edit(count)
    # Utilizes edit_common method from QuestionHelper with specified parameters
    # and converts the result to JSON format
    edit_common("Question #{count}:", txt, weight, type).to_json
  end

  # Method to view the text and details of a dropdown question
  def view_question_text
    # Utilizes view_question_text_common method from QuestionHelper with specified parameters
    # and converts the result to JSON format. 'N/A' signifies that scoring is not applicable
    view_question_text_common(txt, type, weight, 'N/A').to_json
  end

  # Method to prepare the dropdown options for completing a question, marking the selected option
  def complete(count, answer = nil)
    # Generates a list of options based on the count, marking the selected option based on the answer
    options = (1..count).map { |option| { value: option, selected: (option == answer.to_i) } }
    # Returns the dropdown options in JSON format
    { dropdown_options: options }.to_json
  end

  # Similar to the complete method but uses predefined alternatives instead of a numeric range
  def complete_for_alternatives(alternatives, answer)
    # Generates a list of options from the alternatives, marking the selected option based on the answer
    options = alternatives.map { |alt| { value: alt, selected: (alt == answer) } }
    # Returns the dropdown options in JSON format
    { dropdown_options: options }.to_json
  end

  # Method to display the selected option of a completed question
  def view_completed_question
    # Constructs a response indicating the selected option or that the question was not answered
    { selected_option: (count && answer) ? "#{answer} (out of #{count})" : 'Question not answered.' }.to_json
  end
end