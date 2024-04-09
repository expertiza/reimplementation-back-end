require 'rails_helper'

# RSpec tests for the Checkbox class
RSpec.describe Checkbox do
  # Setup a Checkbox instance before each test case
  let!(:checkbox) { Checkbox.new(id: 10, question_type: 'Checkbox', seq: 1.0, txt: 'test txt', weight: 11) }
  # Setup an Answer instance to be used in the tests
  let!(:answer) { Answer.new(answer: 1) }

  # Test suite for the #edit method
  describe '#edit' do
    it 'returns the JSON' do
      # Call the edit method and store the result
      json = checkbox.edit(0)
      # Define the expected JSON structure
      expected_json = {
        remove_button: { type: 'remove_button', action: 'delete', href: "/questions/10", text: 'Remove' },
        seq: { type: 'seq', input_size: 6, value: 1.0, name: "question[10][seq]", id: "question_10_seq" },
        question: { type: 'textarea', cols: 50, rows: 1, name: "question[10][txt]", id: "question_10_txt", placeholder: 'Edit question content here', content: 'test txt' },
        type: { type: 'text', input_size: 10, disabled: true, value: 'Checkbox', name: "question[10][type]", id: "question_10_type" },
        weight: { type: 'weight', placeholder: 'UnscoredQuestion does not need weight' }
      }
      # Assert that the actual JSON matches the expected structure
      expect(json).to eq(expected_json)
    end
  end

  # Test suite for the #complete method
  describe '#complete' do
    # Context when an answer is provided
    context 'when an answer is provided' do
      it 'returns the expected completion structure' do
        # Call the complete method and store the result
        result = checkbox.complete(count, answer)
        # Check for the presence of the previous_question key and that inputs is an array
        expect(result[:previous_question]).to be_present
        expect(result[:inputs]).to be_an(Array)
        # Check that the label text matches the question text and that the script includes the correct function
        expect(result[:label]).to include(text: checkbox.txt)
        expect(result[:script]).to include("checkbox#{count}Changed()")
        # Check that the checkbox is marked as checked
        expect(result[:inputs].last[:checked]).to be true
      end
    end

    # Context when no answer is provided
    context 'when no answer is provided' do
      let(:answer) { OpenStruct.new(answer: nil) } # Mock an empty answer

      it 'returns a structure with the checkbox not checked' do
        # Call the complete method and store the result
        result = checkbox.complete(count, answer)
        # Check that the checkbox is not marked as checked
        expect(result[:inputs].last[:checked]).to be false
      end
    end
  end

  # Test suite for the #view_question_text method
  describe '#view_question_text' do
    it 'returns the JSON' do
      # Call the view_question_text method and store the result
      json = checkbox.view_question_text
      # Define the expected JSON structure
      expected_json = {
        content: 'test txt',
        type: 'Checkbox',
        weight: '11',
        checked_state: 'Checked/Unchecked'
      }
      # Assert that the actual JSON matches the expected structure
      expect(json).to eq(expected_json)
    end
  end

  # Test suite for the #view_completed_question method
  describe '#view_completed_question' do
    it 'returns the JSON' do
      # Call the view_completed_question method with parameters and store the result
      json = checkbox.view_completed_question(0, answer)
      # Define the expected JSON structure
      expected_json = {
        previous_question: { type: 'other' },
        answer: {
          number: 0,
          image: 'Check-icon.png',
          content: 'test txt',
          bold: true
        },
        if_column_header: 'continue'
      }
      # Assert that the actual JSON matches the expected structure
      expect(json).to eq(expected_json)
    end
  end
end