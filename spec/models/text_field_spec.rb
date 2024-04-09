require 'rails_helper'

RSpec.describe TextField, type: :model do
  # Create a TextField instance
  let(:question) { TextField.create(txt: 'Sample Text Question', question_type: 'TextField', size: 'medium', break_before: true) }
  # Create an Answer instance
  let(:answer) { Answer.new(comments: 'This is a sample answer.') }

  describe '#complete' do
    context 'when count is provided' do
      # Test case for returning JSON data for a paragraph with a label and input fields
      it 'returns JSON data for a paragraph with a label and input fields' do
        result = JSON.parse(question.complete(1))
        expect(result['action']).to eq('complete')
        expect(result['data']['type']).to eq('text')
        expect(result['data']['name']).to eq("response[answers][#{question.id}]")
      end
    end

    context 'when count and answer are provided' do
      # Test case for returning JSON data with pre-filled comment value
      it 'returns JSON data with pre-filled comment value' do
        result = JSON.parse(question.complete(1, answer))
        expect(result['data']['value']).to eq(answer.comments)
      end
    end
  end

  describe '#view_completed_question' do
    context "when the question type is 'TextField' and break_before is true" do
      # Test case for returning the formatted JSON for the completed question
      it 'returns the formatted JSON for the completed question' do
        result = JSON.parse(question.view_completed_question(1, []))
        expect(result['data']['type']).to eq('text')
        expect(result['data']['break_before']).to be true
      end
    end

    context "when the question type is not 'TextField' or break_before is false" do
      # Create a TextField instance with different properties
      let(:non_text_field_question) { TextField.create(txt: 'Non-text question', question_type: 'NotTextField', size: 'small', break_before: false) }

      # Test case for returning the formatted JSON for the completed question
      it 'returns the formatted JSON for the completed question' do
        result = JSON.parse(non_text_field_question.view_completed_question(1, []))
        expect(result['data']['break_before']).to be false
      end
    end
  end
end