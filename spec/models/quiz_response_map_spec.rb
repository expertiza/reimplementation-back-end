# frozen_string_literal: true

RSpec.describe QuizResponseMap, type: :model do
    describe 'associations' do
      it 'belongs to quiz_questionnaire' do
        expect(described_class.reflect_on_association(:quiz_questionnaire).macro).to eq(:belongs_to)
      end
  
      it 'belongs to assignment' do
        expect(described_class.reflect_on_association(:assignment).macro).to eq(:belongs_to)
      end
  
      it 'has many quiz_responses' do
        expect(described_class.reflect_on_association(:quiz_responses).macro).to eq(:has_many)
      end
    end
  
    describe '#questionnaire' do
      it 'returns the associated quiz_questionnaire' do
        quiz_questionnaire = double('QuizQuestionnaire')
        quiz_response_map = described_class.new
        allow(quiz_response_map).to receive(:quiz_questionnaire).and_return(quiz_questionnaire)
  
        expect(quiz_response_map.questionnaire).to eq(quiz_questionnaire)
      end
    end
  
    describe '.mappings_for_reviewer' do
      it 'returns mappings for a given reviewer' do
        quiz_response_map = double('QuizResponseMap')
        allow(QuizResponseMap).to receive(:where).with(reviewer_id: 1).and_return([quiz_response_map])
  
        mappings = QuizResponseMap.mappings_for_reviewer(1)
        expect(mappings).to eq([quiz_response_map])
      end
    end

    describe '#get_title' do
      it 'returns the correct title constant' do
        quiz_response_map = QuizResponseMap.new
        expect(quiz_response_map.get_title).to eq(ResponseMapSubclassTitles::QUIZ_RESPONSE_MAP_TITLE)
      end
    end
  end