require 'rails_helper'

RSpec.describe TextField, type: :model do
  describe '#complete' do
    it 'returns JSON with question_id, type, count, and answer' do
      text_field = TextField.new(id: 1, type: 'text')

      answer = double('Answer', comments: 'Test comments')

      json_result = JSON.parse(text_field.complete(1, answer))

      expect(json_result['question_id']).to eq(1)
      expect(json_result['type']).to eq('text')
      expect(json_result['count']).to eq(1)
      expect(json_result['answer']).to eq(answer.to_s)
    end
  end

  describe '#view_completed_question' do
    it 'returns JSON with question_id, type, count, comments, and has_break' do
      text_field = TextField.new(id: 1, type: 'text')
      answer = double('Answer', comments: 'Test comments', question_id: 1)

      allow(Question).to receive(:find_by).with(id: 2).and_return(double('Question', break_before: true))

      json_result = JSON.parse(text_field.view_completed_question(1, answer))

      expect(json_result['question_id']).to eq(1)
      expect(json_result['type']).to eq('text')
      expect(json_result['count']).to eq(1)
      expect(json_result['comments']).to eq('Test comments')
      expect(json_result['has_break']).to eq(true)
    end

    it 'returns JSON with has_break as false if next question has no break' do
      text_field = TextField.new(id: 1, type: 'text')
      answer = double('Answer', comments: 'Test comments', question_id: 1)

      allow(Question).to receive(:find_by).with(id: 2).and_return(nil)

      json_result = JSON.parse(text_field.view_completed_question(1, answer))

      expect(json_result['has_break']).to eq(false)
    end
  end
end
