class TextResponse < Question
  attr_accessor :txt, :type, :weight
  # Validate the presence of the 'size' attribute
  validates :size, presence: true

  # Generate HTML for editing a text-based question in a questionnaire
  def edit(_count)
    {
      form: true,
      question_id: id,
      input_type: type,
      input_text: txt,
    }.to_json
  end

  # Generate HTML for viewing a text-based question in a questionnaire
  def view_question_text
    {
      question_id: id,
      type: type,
      weight: weight
    }.to_json
  end

  # Placeholder method for completing a text-based question
  def complete; end

  # Placeholder method for viewing a completed text-based question
  def view_completed_question; end
end
