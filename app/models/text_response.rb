class TextResponse < Question
  # Validate the presence of the 'size' attribute
  validates :size, presence: true

  # Generate HTML for editing a text-based question in a questionnaire
  def edit(_count)
    render partial: 'edit'
  end

  # Generate HTML for viewing a text-based question in a questionnaire
  def view_question_text
    render partial: 'view'
  end

  # Placeholder method for completing a text-based question
  def complete; end

  # Placeholder method for viewing a completed text-based question
  def view_completed_question; end
end
