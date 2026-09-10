# frozen_string_literal: true

require 'rails_helper'

describe CourseEvaluationQuestionnaire, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }

  let(:questionnaire) do
    CourseEvaluationQuestionnaire.create!(
      name: 'Course Evaluation Test',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: instructor
    )
  end

  describe '#print_name' do
    it 'returns Course Evaluation' do
      expect(CourseEvaluationQuestionnaire.print_name).to eq('Course Evaluation')
    end
  end

  describe '#display_type' do
    it 'sets display_type to Course Evaluation after initialization' do
      expect(questionnaire.display_type).to eq('Course Evaluation')
    end
  end

  describe 'inheritance' do
    it 'is a subclass of Questionnaire' do
      expect(CourseEvaluationQuestionnaire.superclass).to eq(Questionnaire)
    end
  end

  describe 'survey-type behavior' do
    it 'does not implement symbol (raises NotImplementedError)' do
      expect { questionnaire.symbol }.to raise_error(NotImplementedError)
    end

    it 'does not implement get_assessments_for (raises NotImplementedError)' do
      expect { questionnaire.get_assessments_for(double('participant')) }.to raise_error(NotImplementedError)
    end
  end
end
