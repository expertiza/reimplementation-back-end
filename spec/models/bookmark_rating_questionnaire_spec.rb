# frozen_string_literal: true

require 'rails_helper'

describe BookmarkRatingQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    BookmarkRatingQuestionnaire.create!(
      name: 'Bookmark Rating Rubric Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns the correct print name' do
      expect(BookmarkRatingQuestionnaire.print_name).to eq('Bookmark Rating Rubric')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Bookmark Rating after initialization' do
      expect(questionnaire.display_type).to eq('Bookmark Rating')
    end
  end

  describe '#symbol' do
    it 'returns :bookmark' do
      expect(questionnaire.symbol).to eq(:bookmark)
    end
  end

  describe '#get_assessments_for' do
    it 'returns the participant bookmark_reviews' do
      participant = double('participant')
      bookmark_reviews = double('bookmark_reviews')
      allow(participant).to receive(:bookmark_reviews).and_return(bookmark_reviews)
      expect(questionnaire.get_assessments_for(participant)).to eq(bookmark_reviews)
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(BookmarkRatingQuestionnaire.superclass).to eq(Questionnaire)
    end
  end
end
