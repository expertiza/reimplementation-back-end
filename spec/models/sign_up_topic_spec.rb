require 'rails_helper'

RSpec.describe SignUpTopic, type: :model do
  let(:assignment) { create(:assignment) }
  let(:questionnaire) { create(:questionnaire) }
  let(:topic) { create(:sign_up_topic, assignment: assignment) }

  describe 'associations' do
    it { should have_many(:assignment_questionnaires) }
    it { should belong_to(:questionnaire).optional }
  end

  describe '#rubric_for_review' do
    context 'when topic has a specific rubric' do
      before do
        create(:assignment_questionnaire,
               assignment: assignment,
               questionnaire: questionnaire,
               topic: topic)
      end

      it 'returns the topic-specific rubric' do
        expect(topic.rubric_for_review).to eq(questionnaire)
      end
    end

    context 'when topic has no specific rubric' do
      before do
        create(:assignment_questionnaire,
               assignment: assignment,
               questionnaire: questionnaire,
               topic: nil) # default rubric
      end

      it 'falls back to the default assignment rubric' do
        expect(topic.rubric_for_review).to eq(questionnaire)
      end
    end
  end

  describe '#has_specific_rubric?' do
    it 'returns true when topic has a specific rubric' do
      create(:assignment_questionnaire,
             assignment: assignment,
             questionnaire: questionnaire,
             topic: topic)
      
      expect(topic.has_specific_rubric?).to be true
    end

    it 'returns false when topic has no specific rubric' do
      expect(topic.has_specific_rubric?).to be false
    end
  end
end