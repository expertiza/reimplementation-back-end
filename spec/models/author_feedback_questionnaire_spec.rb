# frozen_string_literal: true

require 'rails_helper'

describe AuthorFeedbackQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    AuthorFeedbackQuestionnaire.create!(
      name: 'Author Feedback Rubric Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns the correct print name' do
      expect(AuthorFeedbackQuestionnaire.print_name).to eq('Author Feedback Rubric')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Author Feedback after initialization' do
      expect(questionnaire.display_type).to eq('Author Feedback')
    end
  end

  describe '#symbol' do
    it 'returns :feedback' do
      expect(questionnaire.symbol).to eq(:feedback)
    end
  end

  describe '#get_assessments_for' do
    it 'returns the participant feedback' do
      participant = double('participant')
      feedback = double('feedback')
      allow(participant).to receive(:feedback).and_return(feedback)
      expect(questionnaire.get_assessments_for(participant)).to eq(feedback)
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(AuthorFeedbackQuestionnaire.superclass).to eq(Questionnaire)
    end
  end
end
