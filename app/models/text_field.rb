# Inherits from Question to define specific behaviors for text field questions
class TextField < Question
  # Validates the presence of the size attribute
  validates :size, presence: true

  def complete(count, answer = nil)
    {
      action: 'complete',  # Indicates the action type
      data: {  # Data related to the text field question
        label: "Question ##{count}",  # Label for the question, including its sequence number
        type: 'text',  # Type of input (text field)
        name: "response[answers][#{id}]",  # Name attribute for form submission
        id: "responses_#{id}",  # ID attribute for HTML element
        value: answer&.comments  # Value of the text field, uses safe navigation operator to handle nil
      }
    }.to_json  # Converts the hash to JSON format
  end

  def view_completed_question(count, files)
    {
      action: 'view_completed_question',  # Indicates the action type
      data: {  # Data related to the completed text field question
        type: 'text',  # Type of input (text field)
        label: "Completed Question ##{count}",  # Label for the completed question, including its sequence number
        value: txt,  # Value of the completed text field
        break_before: break_before  # Flag indicating whether to break before this question in the view
      }
    }.to_json  # Converts the hash to JSON format
  end
end