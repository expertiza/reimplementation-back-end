# Inherits from Question to define specific behaviors for text area questions
class TextArea < Question
  
  # Method to construct the completion structure for a text area question
  # @param count [Integer] The sequence number of the question
  # @param answer [Answer, nil] The answer object associated with the question, may be nil if not answered
  # @return [String] JSON representation of the completion structure
  def complete(count, answer = nil)
    {
      action: 'complete',  # Indicates the action type
      data: {  # Data related to the text area question
        count: count,  # The sequence number of the question
        comment: answer&.comments,  # The comment from the answer, uses safe navigation operator to handle nil
        size: size || '70,1',  # The size of the text area, defaults to '70,1' if size is nil
      }
    }.to_json  # Converts the hash to JSON format
  end

  # Method to construct the structure for viewing a completed text area question
  # @param count [Integer] The sequence number of the question
  # @param answer [Answer] The answer object associated with the question
  # @return [String] JSON representation of the completed question view structure
  def view_completed_question(count, answer)
    {
      action: 'view_completed_question',  # Indicates the action type
      data: {  # Data related to the completed text area question
        count: count,  # The sequence number of the question
        comment: answer.comments  # The comment from the answer
      }
    }.to_json  # Converts the hash to JSON format
  end
end