# frozen_string_literal: true

require 'rails_helper'

describe TeammateReviewQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    TeammateReviewQuestionnaire.create!(
      name: 'Team Review Rubric Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns the correct print name' do
      expect(TeammateReviewQuestionnaire.print_name).to eq('Teammate Review Rubric')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Teammate Review after initialization' do
      expect(questionnaire.display_type).to eq('Teammate Review')
    end
  end

  describe '#symbol' do
    it 'returns :teammate' do
      expect(questionnaire.symbol).to eq(:teammate)
    end
  end

  describe '#get_assessments_for' do
    it 'returns the participant teammate_reviews' do
      participant = double('participant')
      teammate_reviews = double('teammate_reviews')
      allow(participant).to receive(:teammate_reviews).and_return(teammate_reviews)
      expect(questionnaire.get_assessments_for(participant)).to eq(teammate_reviews)
    end
  end

  describe '#get_assessments_for_round' do
    it 'returns an empty array when the participant has no TeammateReviewResponseMaps' do
      participant = double('participant', id: 99)
      allow(TeammateReviewResponseMap).to receive(:where).with(reviewer_id: 99).and_return([])
      expect(questionnaire.get_assessments_for_round(participant, 1)).to eq([])
    end

    it 'returns only submitted responses for the given round (uses map.responses, not map.response)' do
      participant   = double('participant', id: 55)

      submitted_res = double('response', round: 1, is_submitted: true)
      unsubmitted   = double('response', round: 1, is_submitted: false)
      wrong_round   = double('response', round: 2, is_submitted: true)

      map = double('map')
      allow(map).to receive(:responses).and_return([submitted_res, unsubmitted, wrong_round])

      allow(TeammateReviewResponseMap).to receive(:where)
        .with(reviewer_id: 55)
        .and_return([map])

      result = questionnaire.get_assessments_for_round(participant, 1)
      expect(result).to eq([submitted_res])
    end
  end

  describe '#has_criterion_items?' do
    context 'when there are no Criterion items' do
      it 'returns false' do
        allow(questionnaire).to receive(:items).and_return([])
        expect(questionnaire.has_criterion_items?).to be false
      end
    end

    context 'when there is at least one Criterion item' do
      it 'returns true' do
        criterion_item = double('item', question_type: 'Criterion')
        allow(questionnaire).to receive(:items).and_return([criterion_item])
        expect(questionnaire.has_criterion_items?).to be true
      end
    end

    context 'when items exist but none are Criterion' do
      it 'returns false' do
        text_item = double('item', question_type: 'TextArea')
        allow(questionnaire).to receive(:items).and_return([text_item])
        expect(questionnaire.has_criterion_items?).to be false
      end
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(TeammateReviewQuestionnaire.superclass).to eq(Questionnaire)
    end
  end
end
