require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  before :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.create_table :questions do |t|
      t.string :type
      t.references :questionnaire, null: false, foreign_key: true
      t.integer :weight
      t.string :size
    end
    m.create_table :assignment_questionnaires do |t|
      t.integer :used_in_round
      t.integer :questionnaire_weight
      t.references :questionnaire, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
    end
    m.create_table :question_advices do |t|
      t.integer :score
      t.text :advice
      t.references :question, null: false, foreign_key: true
    end
    m.create_table :instructors do |t|
      t.string :name
      t.string :fullname
      t.string :email
      t.string :password
    end
    m.create_table :questionnaire_nodes do |t|
      t.integer :node_object_id
    end
  end

  after :all do
    m = ActiveRecord::Migration.new
    m.verbose = false
    m.drop_table :question_advices
    m.drop_table :questions
    m.drop_table :assignment_questionnaires
    m.drop_table :instructors
    m.drop_table :questionnaire_nodes
  end

  let(:role) { build_stubbed(:role) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', fullname: 'Test Instructor', password: '123456', role: role) }
  let(:questionnaire) { build_stubbed(:questionnaire, instructor_id: instructor.id) }
  let(:question1) { build_stubbed(:question, questionnaire_id: questionnaire) }
  let(:question2) { build_stubbed(:question, questionnaire_id: questionnaire, type: "Checkbox", weight: 5) }
  let(:questionnaire_node) { build_stubbed(:questionnaire_node, node_object_id: questionnaire) }
  let(:questionnaire2) { build(:questionnaire, id: 2, type: 'MetareviewQuestionnaire') }
  let(:assignment) { build_stubbed(:assignment, id: 1, name: 'no assignment') }
  let(:assignment_questionnaire1) { build_stubbed(:assignment_questionnaire, questionnaire_weight: 100, id: 1, assignment_id: 1, questionnaire_id: 2, used_in_round: nil) }

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
    it "uniqueness in combination with instructor_id is validated" do
      should validate_uniqueness_of(:name).with_message('Questionnaire names must be unique.').scoped_to(:instructor_id).case_insensitive
    end
    it 'when creating a questionnaire with a duplicate name as the same instructor' do
      dupe_questionnaire1 = Questionnaire.create(name: 'dupe', min_question_score: 0, max_question_score: 10, instructor_id: instructor.id)
      dupe_questionnaire2 = Questionnaire.create(name: 'dupe', min_question_score: 0, max_question_score: 10, instructor_id: instructor.id)
      dupe_questionnaire1.valid?
      dupe_questionnaire2.valid?
      expect(dupe_questionnaire1).to be_valid
      expect(dupe_questionnaire2.errors[:name]).to include('Questionnaire names must be unique.')
    end
    it 'when creating a questionnaire with a duplicate name as different instructors' do
      instructor2 = Instructor.create(id: 1002, name: 'testinstructortwo', email: 'test@test.com', fullname: 'Test Instructor2', password: '123456', role: role)
      instructor2.valid?
      expect(instructor2).to be_valid
      dupe_questionnaire1 = Questionnaire.create(name: 'valid_dupe', min_question_score: 0, max_question_score: 10, instructor_id: instructor.id)
      dupe_questionnaire2 = Questionnaire.create(name: 'valid_dupe', min_question_score: 0, max_question_score: 10, instructor_id: instructor2.id)
      dupe_questionnaire1.valid?
      dupe_questionnaire2.valid?
      expect(dupe_questionnaire1).to be_valid
      expect(dupe_questionnaire2).to be_valid
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

  describe "has_true_false_questions" do
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
      questionnaire2 = build(:questionnaire, name: 'questionnaire with no questions', min_question_score: 0, max_question_score: 5)
      expect(questionnaire2.has_true_false_questions).to eq(false)
    end
  end

  describe 'self.copy_questionnaire_details' do
    it 'allowing calls from copy_questionnaire_details' do
      questionnaire_to_be_cloned = Questionnaire.create(name: 'clone me', min_question_score: 0, max_question_score: 10, instructor_id: instructor.id)
      criterion_q = Criterion.create(questionnaire_id: questionnaire_to_be_cloned.id)
      question_to_clone = Question.create(questionnaire_id: questionnaire_to_be_cloned.id)
      allow(questionnaire_to_be_cloned).to receive(:questions).and_return([criterion_q, question_to_clone])
      question_advice = QuestionAdvice.create(question_id: criterion_q.id)
      allow(criterion_q).to receive(:question_advices).and_return([question_advice])
      params = { id: questionnaire_to_be_cloned.id }
      cloned_questionnaire = Questionnaire.copy_questionnaire_details(params, questionnaire_to_be_cloned.instructor_id)
      expect(cloned_questionnaire).to be_a(Questionnaire)
      expect(Questionnaire.find_by(id: cloned_questionnaire.id)).to be_truthy
      expect(cloned_questionnaire.questions.count).to eq(2)
      expect(Criterion.find_by(questionnaire_id: cloned_questionnaire.id).size).to eq('50,3')
      expect(QuestionAdvice.joins(:question).where('questions.questionnaire_id = ?', cloned_questionnaire).count).to eq (1)
    end
  end

  describe "questionnaire max possible score" do
    it 'scenario 1' do
      allow(questionnaire).to receive(:questions).and_return([question1, question2])
      expect(questionnaire.max_possible_score).to eq(35)
    end
    it 'scenario 2' do
      # adding a third question to scenario 1
      question3 = build_stubbed(:question, questionnaire_id: questionnaire, type: "Dropdown", weight: 4)
      allow(questionnaire).to receive(:questions).and_return([question1, question2, question3])
      expect(questionnaire.max_possible_score).to eq(55)
    end
    it 'scenario 3' do
      # adding a third question to scenario 1
      question3 = build_stubbed(:question, questionnaire_id: questionnaire, type: "Dropdown", weight: 4)
      # adding a change to the max_question_score on questionnaire
      questionnaire.max_question_score = 10
      allow(questionnaire).to receive(:questions).and_return([question1, question2, question3])
      expect(questionnaire.max_possible_score).to eq(110)
    end
  end

  describe '#get_weighted_score' do
    context 'when there are no rounds' do
      it 'just uses the symbol with no round' do
        allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 2).and_return(assignment_questionnaire1)
        allow(assignment_questionnaire1).to receive(:used_in_round).and_return(nil)
        allow(questionnaire2).to receive(:symbol).and_return('a')
        allow(questionnaire2).to receive(:assignment_questionnaires).and_return(assignment_questionnaire1)
        allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 2).and_return(assignment_questionnaire1)
        scores = { 'a' => { scores: { avg: 100 } } }
        expect(questionnaire2.get_weighted_score(assignment, scores)).to eq(100)
      end
    end
  end

end
