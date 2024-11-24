require 'rails_helper'

RSpec.describe TextResponse, type: :model do
  let(:text_response) { TextResponse.create(seq: '001', txt: 'Sample question content', question_type: 'TextResponse', size: 'medium', weight: 10) }

  describe '#edit' do
    let(:result) { JSON.parse(text_response.edit(1)) }

    it 'returns JSON for editing with correct action' do
      expect(result["action"]).to eq('edit')
    end

    it 'includes elements for editing question' do
      expect(result["elements"].length).to be > 0
    end
  end

  describe '#view_question_text' do
    let(:result) { JSON.parse(text_response.view_question_text) }

    it 'returns JSON for viewing question text with correct action' do
      expect(result["action"]).to eq('view_question_text')
    end

    it 'includes the question text, question_type, and weight in elements' do
      expect(result["elements"].any? { |e| e["value"] == 'Sample question content' }).to be true
      expect(result["elements"].any? { |e| e["value"] == 'TextResponse' }).to be true
      expect(result["elements"].any? { |e| e["value"].match?(/^\d+$/) }).to be true
    end
  end

end