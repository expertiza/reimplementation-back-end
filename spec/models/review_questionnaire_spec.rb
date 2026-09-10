# frozen_string_literal: true

require 'rails_helper'

describe ReviewQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    ReviewQuestionnaire.create!(
      name: 'Review Rubric Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns the correct print name' do
      expect(ReviewQuestionnaire.print_name).to eq('Review Rubric')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Review after initialization' do
      expect(questionnaire.display_type).to eq('Review')
    end
  end

  describe '#symbol' do
    it 'returns :review' do
      expect(questionnaire.symbol).to eq(:review)
    end
  end

  describe '#get_assessments_for' do
    it 'returns the participant reviews' do
      participant = double('participant')
      reviews = double('reviews')
      allow(participant).to receive(:reviews).and_return(reviews)
      expect(questionnaire.get_assessments_for(participant)).to eq(reviews)
    end
  end

  describe '#get_assessments_for_round' do
    it 'returns nil if the participant has no team' do
      participant = double('participant')
      allow(AssignmentTeam).to receive(:team).with(participant).and_return(nil)
      expect(questionnaire.get_assessments_for_round(participant, 1)).to be_nil
    end

    it 'returns only submitted responses for the given round (uses map.responses, not map.response)' do
      participant   = double('participant')
      team          = double('team', id: 42)
      allow(AssignmentTeam).to receive(:team).with(participant).and_return(team)

      # Build two fake responses: one matching round + submitted, one not submitted
      reviewer      = double('reviewer', fullname: 'Alice Tester')
      submitted_res = double('response', round: 1, is_submitted: true, map: double(reviewer: reviewer))
      unsubmitted   = double('response', round: 1, is_submitted: false)
      wrong_round   = double('response', round: 2, is_submitted: true)

      map = double('map')
      allow(map).to receive(:responses).and_return([submitted_res, unsubmitted, wrong_round])

      allow(ResponseMap).to receive(:where)
        .with(reviewee_id: 42, type: 'ReviewResponseMap')
        .and_return([map])

      result = questionnaire.get_assessments_for_round(participant, 1)
      expect(result).to eq([submitted_res])
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(ReviewQuestionnaire.superclass).to eq(Questionnaire)
    end
  end
end
