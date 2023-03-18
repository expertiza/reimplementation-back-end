require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  before :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.create_table :questions do |t|
      t.string :type
      t.references :questionnaire, null: false, foreign_key: true
    end
    m.create_table :assignment_questionnaires do |t|
      t.references :questionnaire, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
    end
    m.create_table :instructors do |t|
      t.string :name
    end
  end

  after :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :assignment_questionnaires
    m.drop_table :instructors
    m.drop_table :questions
  end

  let(:instructor) { Instructor.create(name: 'test instructor') }
  let(:questionnaire) { Questionnaire.create(name: 'abc', private: 0, min_question_score: 0, max_question_score: 5, instructor_id: 1234) }
  let(:question1) { Question.create questionnaire_id: questionnaire, type: "Dropdown" }
  let(:question2) { Question.create questionnaire_id: questionnaire, type: "Checkbox" }

  it "associated questions are dependent destroyed" do
    expect(questionnaire).to have_many(:questions).dependent(:destroy)
  end

  it "associated assignment questionnaires are dependent destroyed" do
    expect(questionnaire).to have_many(:assignment_questionnaires).dependent(:destroy)
  end

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
      dupe_questionnaire1 = Questionnaire.create(name: 'dupe', min_question_score: 0, max_question_score: 10, instructor_id: 1234)
      dupe_questionnaire2 = Questionnaire.create(name: 'dupe', min_question_score: 0, max_question_score: 10, instructor_id: 1234)
      dupe_questionnaire2.valid?
      expect(dupe_questionnaire1).to be_valid
      expect(dupe_questionnaire2.errors[:name]).to include('Questionnaire names must be unique.')
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

  describe "questionnaire" do
    it 'when contains true/false questions' do
      allow(questionnaire).to receive(:questions).and_return([question1, question2])
      expect(questionnaire.has_true_false_questions).to eq(true)
    end
    it 'when does not contain true/false questions' do
      allow(questionnaire).to receive(:questions).and_return([question1, question2])
      question2.type = "Dropdown"
      expect(questionnaire.has_true_false_questions).to eq(false)
    end
    it 'when there are no associated questions' do
      questionnaire2 = Questionnaire.create(name: 'questionnaire with no questions', min_question_score: 0, max_question_score: 5)
      expect(questionnaire2.has_true_false_questions).to eq(false)
    end
  end
end
