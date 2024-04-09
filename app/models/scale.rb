# Inherits from ScoredQuestion and includes QuestionHelper for shared functionalities
class Scale < ScoredQuestion
  include QuestionHelper

  # Define accessible attributes for instances of Scale
  attr_accessor :txt, :type, :weight, :min_label, :max_label, :answer, :min_question_score, :max_question_score

  # Prepares and returns the JSON structure for editing a scale question
  def edit
    # Calls edit_common from QuestionHelper with question parameters and converts to JSON
    edit_common('Question:', min_question_score, max_question_score, txt, weight, type).to_json
  end

  # Generates the JSON structure for viewing the question text and details
  def view_question_text
    # Calls view_question_text_common from QuestionHelper with question parameters, including the score range
    view_question_text_common(txt, type, weight, score_range).to_json
  end

  # Prepares the scale options for question completion and marks the selected option
  def complete
    # Generates a list of options from min to max score, marking the selected option
    options = (@min_question_score..@max_question_score).map do |option|
      { value: option, selected: (option == answer) }
    end
    # Returns the scale options in JSON format
    { scale_options: options }.to_json
  end

  # Displays the selected option for a completed question or indicates if unanswered
  def view_completed_question(options = {})
    # If sufficient data is provided in options, construct a response with count, answer, and max questionnaire score
    if options[:count] && options[:answer] && options[:questionnaire_max]
      { count: options[:count], answer: options[:answer], questionnaire_max: options[:questionnaire_max] }.to_json
    else
      # If data is insufficient, return a message indicating the question was not answered
      { message: 'Question not answered.' }.to_json
    end
  end

  private

  # Helper method to construct the score range string, incorporating labels if provided
  def score_range
    # If min and max labels are not provided, use just the score numbers; otherwise, include the labels in the format
    min_label.nil? && max_label.nil? ? "#{@min_question_score} to #{@max_question_score}" :
      "#{min_label} #{@min_question_score} to #{@max_question_score} #{max_label}"
  end
end