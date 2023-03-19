require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  let(:questionnaire) { Questionnaire.create name: 'abc', private: 0, min_question_score: 0, max_question_score: 5, instructor_id: 1234 }

  describe "name" do
    it "presence is validated" do
      should validate_presence_of(:name)
    end
    it "when name is not present" do
      questionnaire.name = ''
      expect(questionnaire).not_to be_valid
    end
    it 'when name is valid' do
      questionnaire.name = 'valid questionnaire'
      expect(questionnaire).to be_valid
    end
    it "uniqueness is validated" do
      should validate_uniqueness_of(:name).with_message('Questionnaire names must be unique.').case_insensitive
    end
    it 'when creating a questionnaire with a duplicate name' do
      dupe_questionnaire = Questionnaire.create(name: 'abc', min_question_score: 0, max_question_score: 5)
      dupe_questionnaire.valid?
      expect(dupe_questionnaire.errors[:name]).to include('Questionnaire names must be unique.')
    end
  end

  describe "min question score and max question score" do
    it "numericality is validated" do
      should validate_numericality_of(:min_question_score)
      should validate_numericality_of(:max_question_score)
    end
    it "when min question score is not numeric" do
      questionnaire.name = 'invalid questionnaire'
      questionnaire.min_question_score = 'abc'
      expect(questionnaire).not_to be_valid
    end
    it "when max question score is not numeric" do
      questionnaire.name = 'invalid questionnaire'
      questionnaire.max_question_score = 'abc'
      expect(questionnaire).not_to be_valid
    end
    it 'when min question score is not a positive integer' do
      questionnaire.name = 'invalid questionnaire'
      questionnaire.min_question_score = -1
      questionnaire.valid?
      expect(questionnaire.errors[:min_question_score]).to include('The minimum question score must be a positive integer.')
    end
    it 'when max question score is not a non-zero positive integer' do
      questionnaire.name = 'invalid questionnaire'
      questionnaire.max_question_score = 0
      questionnaire.valid?
      expect(questionnaire.errors[:max_question_score]).to include('The maximum question score must be a positive integer greater than 0.')
    end
    it 'when minimum question score is greater than maximum question score' do
      questionnaire.name = 'invalid questionnaire'
      questionnaire.min_question_score = 3
      questionnaire.max_question_score = 1
      questionnaire.valid?
      expect(questionnaire.errors[:max_question_score]).to include('The minimum question score must be less than the maximum.')
    end
    it 'when min question score and max question score are valid' do
      questionnaire.name = 'valid questionnaire'
      questionnaire.min_question_score = 1
      questionnaire.max_question_score = 10
      expect(questionnaire).to be_valid
    end
  end
end
