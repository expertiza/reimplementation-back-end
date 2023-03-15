require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  before(:all) do
    #change to let?
    @questionnaire = Questionnaire.create(name: 'abc', private: 0, min_question_score: 0, max_question_score: 10, instructor_id: 1234)
  end

  describe "name" do
    it "presence is validated" do
      should validate_presence_of(:name)
    end
    it "when name is not present" do
      #replace with something like build?
      questionnaire = Questionnaire.create(name: '', min_question_score: 0, max_question_score: 5)
      expect(questionnaire).not_to be_valid
    end
    it 'when name is valid' do
      questionnaire = Questionnaire.create(name: 'abc', min_question_score: 0, max_question_score: 5)
      expect(questionnaire).to be_valid
    end
    it 'when questionnaire name is not unique' do
      questionnaire1 = Questionnaire.create(id: 1, name: 'abc', instructor_id: 1)
      questionnaire2 = Questionnaire.create(id: 2, name: 'abc', instructor_id: 1)
      questionnaire2.valid?
      expect(questionnaire2.errors[:name]).to include('Questionnaire names must be unique.')
    end
  end

  describe "min question score and max question score" do
    it "numericality is validated" do
      should validate_numericality_of(:min_question_score)
      should validate_numericality_of(:max_question_score)
    end
    it "when min question score is not numeric" do
      questionnaire = Questionnaire.create(min_question_score: 'abc')
      expect(questionnaire).not_to be_valid
    end
    it "when max question score is not numeric" do
      questionnaire = Questionnaire.create(max_question_score: 'abc')
      expect(questionnaire).not_to be_valid
    end
    it 'when min question score is not a positive integer' do
      questionnaire = Questionnaire.create(min_question_score: -1)
      questionnaire.valid?
      expect(questionnaire.errors[:min_question_score]).to include('The minimum question score must be a positive integer.')
    end
    it 'when max question score is not a non-zero positive integer' do
      questionnaire = Questionnaire.create(max_question_score: 0)
      questionnaire.valid?
      expect(questionnaire.errors[:max_question_score]).to include('The maximum question score must be a non-zero positive integer.')
    end
    it 'when minimum question score is greater than maximum question score' do
      questionnaire = Questionnaire.create(min_question_score: 3, max_question_score: 1)
      questionnaire.valid?
      expect(questionnaire.errors[:max_question_score]).to include('The minimum question score must be less than the maximum.')
    end
    it 'when min question score and max question score are valid' do
      #DRY violation with valid name test above
      questionnaire = Questionnaire.create(name: 'abc', min_question_score: 0, max_question_score: 5)
      expect(questionnaire).to be_valid
    end
  end
end
