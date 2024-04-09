require 'rails_helper'

# RSpec test suite for MultipleChoiceCheckbox model
RSpec.describe MultipleChoiceCheckbox, type: :model do
  # Setup a sample instance of MultipleChoiceCheckbox for use in tests
  let(:multiple_choice_checkbox) { MultipleChoiceCheckbox.new(id: 1, txt: 'Test question:', weight: 1) }

  # Tests for the #edit method
  describe '#edit' do
    it 'returns the JSON structure for editing' do
      # Setup a mock object for QuizQuestionChoice with predefined attributes
      qc = instance_double('QuizQuestionChoice', iscorrect: true, txt: 'question text', id: 1)
      # Stub the .where method to return a predefined set of choices
      allow(QuizQuestionChoice).to receive(:where).with(question_id: 1).and_return([qc, qc, qc, qc])

      # Define the expected JSON structure
      expected_structure = {
        "id" => 1,
        "question_text" => "Test question:",
        "weight" => 1,
        "choices" => [
          {"id" => 1, "text" => "question text", "is_correct" => true, "position" => 1},
          {"id" => 1, "text" => "question text", "is_correct" => true, "position" => 2},
          {"id" => 1, "text" => "question text", "is_correct" => true, "position" => 3},
          {"id" => 1, "text" => "question text", "is_correct" => true, "position" => 4}
        ]
      }.to_json

      # Verify that the edit method returns the expected JSON structure
      expect(multiple_choice_checkbox.edit).to eq(expected_structure)
    end
  end

  # Tests for the #isvalid method
  describe '#isvalid' do
    context 'when the question itself does not have txt' do
      it 'returns a JSON with error message' do
        # Stub the txt method to return an empty string to simulate a question without text
        allow(multiple_choice_checkbox).to receive_messages(txt: '', id: 1)
        # Define a set of question choices
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: 'question text', iscorrect: '1' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        # Define the expected JSON response with an error message
        expected_response = { valid: false, error: 'Please make sure all questions have text' }.to_json
        # Verify that the isvalid method returns the expected response
        expect(multiple_choice_checkbox.isvalid(questions)).to eq(expected_response)
      end
    end

    context 'when a choice does not have txt' do
      it 'returns a JSON with error message' do
        # Define a set of question choices with empty text
        questions = { '1' => { txt: '', iscorrect: '1' }, '2' => { txt: '', iscorrect: '1' }, '3' => { txt: '', iscorrect: '0' }, '4' => { txt: '', iscorrect: '0' } }
        # Define the expected JSON response indicating the choices are valid despite missing text
        expected_response = { valid: true, error: nil }.to_json
        # Verify that the isvalid method returns the expected response
        expect(multiple_choice_checkbox.isvalid(questions)).to eq(expected_response)
      end
    end

    context 'when no choices are correct' do
      it 'returns a JSON with error message' do
        # Define a set of question choices with no correct answers
        questions = { '1' => { txt: 'question text', iscorrect: '0' }, '2' => { txt: 'question text', iscorrect: '0' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        # Define the expected JSON response with an error message about needing a correct answer
        expected_response = { valid: false, error: 'Please select a correct answer for all questions' }.to_json
        # Verify that the isvalid method returns the expected response
        expect(multiple_choice_checkbox.isvalid(questions)).to eq(expected_response)
      end
    end

    context 'when only one choice is correct' do
      it 'returns a JSON with error message' do
        # Define a set of question choices with only one correct answer
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: 'question text', iscorrect: '0' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        # Define the expected JSON response with an error message for having only one correct answer in a multiple-choice question
        expected_response = { valid: false, error: 'A multiple-choice checkbox question should have more than one correct answer.' }.to_json
        # Verify that the isvalid method returns the expected response
        expect(multiple_choice_checkbox.isvalid(questions)).to eq(expected_response)
      end
    end

    context 'when 2 choices are correct' do
      it 'returns valid status' do
        # Define a set of question choices with two correct answers
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: 'question text', iscorrect: '1' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        # Define the expected JSON response indicating the question is valid
        expected_response = { valid: true, error: nil}.to_json
        # Verify that the isvalid method returns the expected response
        expect(multiple_choice_checkbox.isvalid(questions)).to eq(expected_response)
      end
    end
  end
end