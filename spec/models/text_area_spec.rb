require 'rails_helper'

RSpec.describe TextArea do
  # Create a TextArea instance
  let(:text_area) { TextArea.create(size: '34,1') }
  # Create an Answer instance
  let!(:answer) { Answer.create(comments: 'test comment') }

  describe '#complete' do
    context 'when count is provided' do
      # Test case for generating JSON for a textarea input
      it 'generates JSON for a textarea input' do
        result = JSON.parse(text_area.complete(1))
        expect(result['action']).to eq('complete')
        expect(result['data']['count']).to eq(1)
        expect(result['data']['size']).to eq('34,1')
      end

      # Test case for including existing comments in the textarea input
      it 'includes any existing comments in the textarea input' do
        result = JSON.parse(text_area.complete(1, answer))
        expect(result['data']['comment']).to eq('test comment')
      end
    end

    context 'when count is not provided' do
      # Test case for generating JSON with default size for the textarea input
      it 'generates JSON with default size for the textarea input' do
        text_area = TextArea.create(size: nil)
        result = JSON.parse(text_area.complete(nil))
        expect(result['data']['size']).to eq('70,1')
      end
    end
  end

  describe 'view_completed_question' do
    context 'when given a count and an answer' do
      # Test case for returning the formatted JSON for the completed question
      it 'returns the formatted JSON for the completed question' do
        result = JSON.parse(text_area.view_completed_question(1, answer))
        expect(result['action']).to eq('view_completed_question')
        expect(result['data']['comment']).to eq('test comment')
      end
    end
  end
end
