# frozen_string_literal: true

require 'rails_helper'

describe SurveyQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    SurveyQuestionnaire.create!(
      name: 'Survey Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns Survey' do
      expect(SurveyQuestionnaire.print_name).to eq('Survey')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Survey after initialization' do
      expect(questionnaire.display_type).to eq('Survey')
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(SurveyQuestionnaire.superclass).to eq(Questionnaire)
    end
  end

  describe GlobalSurveyQuestionnaire do
    let(:global_survey) do
      GlobalSurveyQuestionnaire.create!(
        name: 'Global Survey Test',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor: instructor
      )
    end

    it 'has the correct print_name' do
      expect(GlobalSurveyQuestionnaire.print_name).to eq('Global Survey')
    end

    it 'sets display_type to Global Survey' do
      expect(global_survey.display_type).to eq('Global Survey')
    end

    it 'inherits directly from Questionnaire (not SurveyQuestionnaire)' do
      expect(GlobalSurveyQuestionnaire.superclass).to eq(Questionnaire)
    end
  end
end
