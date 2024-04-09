require 'rails_helper'

# RSpec test suite for the Dropdown model
RSpec.describe Dropdown, type: :model do

  # Test suite for the #edit method
  describe '#edit' do
    # Context when a count is provided to the method
    context 'when given a count' do
      it 'returns a JSON object with the edit form for a question' do
        # Initialize a Dropdown instance with specific attributes
        dropdown = Dropdown.new(txt: "Some Text", type: "dropdown", weight: 1)
        # Call the edit method with a count argument and store the result
        json_result = dropdown.edit(5)

        # Define the expected JSON structure
        expected_result = {
          form: true,
          label: "Question 5:",
          input_type: "text",
          input_name: "question",
          input_value: "Some Text",
          min_question_score: nil,
          max_question_score: nil,
          weight: 1,
          type: 'dropdown'
        }.to_json
        # Assert that the actual result matches the expected result
        expect(json_result).to eq(expected_result)
      end
    end
  end

  # Test suite for the #view_question_text method
  describe '#view_question_text' do
    # Using let to define a reusable Dropdown instance for the tests in this block
    let(:dropdown) { Dropdown.new }
    context 'when given valid inputs' do
      it 'returns the JSON for displaying the question text, type, weight, and score range' do
        # Stub methods to return specific values
        allow(dropdown).to receive(:txt).and_return("Question 1")
        allow(dropdown).to receive(:type).and_return("Multiple Choice")
        allow(dropdown).to receive(:weight).and_return(1)

        # Define the expected JSON structure
        expected_json = {
          text: "Question 1",
          type: "Multiple Choice",
          weight: 1,
          score_range: "N/A"
        }.to_json
        # Assert that the view_question_text method returns the expected JSON
        expect(dropdown.view_question_text).to eq(expected_json)
      end
    end
  end

  # Test suite for the #complete method
  describe '#complete' do
    let(:dropdown) { Dropdown.new }  # Reusable Dropdown instance for these tests
    context 'when count is provided' do
      it 'generates JSON for a select input with the given count' do
        count = 3  # Define a count for the options
        # Define the expected JSON structure for dropdown options
        expected_json = {
          dropdown_options: [
            { value: 1, selected: false },
            { value: 2, selected: false },
            { value: 3, selected: false }
          ]
        }.to_json
        # Assert that the complete method returns the expected JSON
        expect(dropdown.complete(count)).to eq(expected_json)
      end
    end

    context 'when answer is provided' do
      it 'generates JSON with the provided answer selected' do
        count = 3  # Define a count for the options
        answer = 2  # Specify the selected answer
        # Define the expected JSON structure with the selected answer
        expected_json = {
          dropdown_options: [
            { value: 1, selected: false },
            { value: 2, selected: true },
            { value: 3, selected: false }
          ]
        }.to_json
        # Assert that the complete method returns the expected JSON with the answer selected
        expect(dropdown.complete(count, answer)).to eq(expected_json)
      end
    end

    context 'when answer is not provided' do
      it 'generates JSON without any answer selected' do
        count = 3  # Define a count for the options
        # Define the expected JSON structure with no selected answers
        expected_json = {
          dropdown_options: [
            { value: 1, selected: false },
            { value: 2, selected: false },
            { value: 3, selected: false }
          ]
        }.to_json
        # Assert that the complete method returns the expected JSON with no answers selected
        expect(dropdown.complete(count)).to eq(expected_json)
      end
    end
  end

  # Test suite for the #complete_for_alternatives method
  describe '#complete_for_alternatives' do
    let(:dropdown) { Dropdown.new }  # Reusable Dropdown instance for these tests
    context 'when given an array of alternatives and an answer' do
      it 'returns JSON options with the selected alternative marked' do
        alternatives = [1, 2, 3]  # Define an array of alternative options
        answer = 2  # Specify the selected answer
        # Define the expected JSON structure with the selected alternative
        expected_json = {
          dropdown_options: [
            { value: 1, selected: false },
            { value: 2, selected: true },
            { value: 3, selected: false }
          ]
        }.to_json
        # Assert that the complete_for_alternatives method returns the expected JSON with the selected alternative
        expect(dropdown.complete_for_alternatives(alternatives, answer)).to eq(expected_json)
      end
    end
  end
end