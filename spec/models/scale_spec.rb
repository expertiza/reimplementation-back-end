require 'rails_helper'

# RSpec tests for the Scale model
RSpec.describe Scale, type: :model do

  # Define the subject of the tests as a new instance of Scale
  subject { Scale.new }

  # Set up initial attributes for the Scale instance before each test
  before do
    subject.txt = "Rate your experience"
    subject.type = "Scale"
    subject.weight = 1
    subject.min_label = "Poor"
    subject.max_label = "Excellent"
    subject.min_question_score = 1
    subject.max_question_score = 5
    subject.answer = 3
  end

  # Test suite for the #edit method
  describe "#edit" do

    it 'returns a JSON object with question text, type, weight, and score range' do
      # Create a new instance of Scale with specific attributes for testing
      scale = Scale.new(txt: 'Scale Question', type: 'scale', weight: 2, min_question_score: 0, max_question_score: 10)

      # Call the edit method and store the result
      json_result = scale.edit

      # Define the expected JSON structure
      expected_result = {
        form: true,
        label: "Question:",
        input_type: "text",
        input_name: "question",
        input_value: "Scale Question",
        min_question_score: 0,
        max_question_score: 10,
        weight: 2,
        type: 'scale'
      }.to_json
      # Assert that the actual result matches the expected result
      expect(json_result).to eq(expected_result)
    end
  end

  # Test suite for the #view_question_text method
  describe "#view_question_text" do
    it "returns JSON containing the question text" do
      # Define the expected JSON structure for the question text
      expected_json = {
        text: "Rate your experience",
        type: "Scale",
        weight: 1,
        score_range: "Poor 1 to 5 Excellent"
      }.to_json
      # Assert that the view_question_text method returns the expected JSON
      expect(subject.view_question_text).to eq(expected_json)
    end
  end

  # Test suite for the #complete method
  describe "#complete" do
    it "returns JSON with scale options" do
      # Define the expected JSON structure for the scale options
      expected_json = { scale_options: [
        { value: 1, selected: false },
        { value: 2, selected: false },
        { value: 3, selected: true },
        { value: 4, selected: false },
        { value: 5, selected: false }
      ] }.to_json
      # Assert that the complete method returns the expected JSON
      expect(subject.complete).to eq(expected_json)
    end
  end

  # Test suite for the #view_completed_question method
  describe "#view_completed_question" do
    context "when the question has been answered" do
      it "returns JSON with the count, answer, and questionnaire_max" do
        # Define options to simulate the question being answered
        options = { count: 10, answer: 3, questionnaire_max: 50 }
        # Define the expected JSON structure when the question is answered
        expected_json = options.to_json
        # Assert that the view_completed_question method returns the expected JSON when answered
        expect(subject.view_completed_question(options)).to eq(expected_json)
      end
    end

    context "when the question has not been answered" do
      it "returns a message indicating the question was not answered" do
        # Define the expected JSON structure when the question is not answered
        expected_json = { message: "Question not answered." }.to_json
        # Assert that the view_completed_question method returns the expected JSON when not answered
        expect(subject.view_completed_question).to eq(expected_json)
      end
    end
  end
end