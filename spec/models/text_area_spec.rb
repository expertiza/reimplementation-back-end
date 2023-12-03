require 'rails_helper'

RSpec.describe TextArea, type: :model do
  describe '#complete' do
    it 'returns JSON with question_id, type, cols, rows, and count' do
      text_area = TextArea.new(id: 1, type: 'text', size: '40,5')

      json_result = JSON.parse(text_area.complete(1))

      expect(json_result['question_id']).to eq(1)
      expect(json_result['type']).to eq('text')
      expect(json_result['cols']).to eq(40)
      expect(json_result['rows']).to eq(5)
      expect(json_result['count']).to eq(1)
    end

    it 'handles size not provided' do
      text_area = TextArea.new(id: 1, type: 'text', size: nil)

      json_result = JSON.parse(text_area.complete(1))

      expect(json_result['cols']).to eq(70) # default value
      expect(json_result['rows']).to eq(1)  # default value
    end
  end

  describe '#view_completed_question' do
    it 'returns JSON with question_id, type, comments, and count' do
      answer = double('Answer', comments: 'Test comments^pLine 1\nLine 2')
      text_area = TextArea.new(id: 1, type: 'text')

      json_result = JSON.parse(text_area.view_completed_question(1, answer))

      expect(json_result['question_id']).to eq(1)
      expect(json_result['type']).to eq('text')
      expect(json_result['comments']).to eq('Test commentsLine 1\\nLine 2')
      expect(json_result['count']).to eq(1)
    end
  end
end
