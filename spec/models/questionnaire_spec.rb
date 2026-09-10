# frozen_string_literal: true

require 'rails_helper'
describe Questionnaire, type: :model do
  # Creating dummy objects for the test with the help of let statement
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) do
    Instructor.create(
      name: 'testinstructor',
      email: 'test@test.com',
      full_name: 'Test Instructor',
      password: '123456',
      role_id: role.id
    )
  end
  let(:questionnaire) do
    Questionnaire.create!(
      name: 'abc',
      private: false,
      min_question_score: 0,
      max_question_score: 10,
      instructor: instructor
    )
  end
  let(:questionnaire1) do
    Questionnaire.new(name: 'xyz', private: 0, max_question_score: 20, instructor_id: instructor.id)
  end
  let(:questionnaire2) do
    Questionnaire.new(name: 'pqr', private: 0, max_question_score: 10, instructor_id: instructor.id)
  end
  let(:question1) do
    questionnaire.items.build(weight: 1, seq: 1, txt: 'que 1', question_type: 'scale', break_before: true)
  end
  let(:question2) do
    questionnaire.items.build(weight: 10, seq: 2, txt: 'que 2', question_type: 'multiple_choice', break_before: true)
  end

  describe '#name' do
    # Test validates the name of the questionnaire
    it 'returns the name of the Questionnaire' do
      expect(questionnaire.name).to eq('abc')
      expect(questionnaire1.name).to eq('xyz')
      expect(questionnaire2.name).to eq('pqr')
    end

    # Test ensures that the name field of the questionnaire is not blank
    it 'Validate presence of name which cannot be blank' do
      questionnaire.name = '  '
      expect(questionnaire).not_to be_valid
    end
  end

  describe '#instructor_id' do
    # Test validates the instructor id in the questionnaire
    it 'returns the instructor id' do
      expect(questionnaire.instructor_id).to eq(instructor.id)
    end
  end

  describe '#maximum_score' do
    # Test validates the maximum score in the questionnaire
    it 'validate maximum score' do
      expect(questionnaire.max_question_score).to eq(10)
    end

    # Test ensures maximum score is an integer
    it 'validate maximum score is integer' do
      expect(questionnaire.max_question_score).to eq(10)
      questionnaire.max_question_score = 'a'
      expect(questionnaire).not_to be_valid
    end

    # Max score is no longer required to be positive — only min < max is enforced.
    it 'allows max_question_score of 0 when min is negative' do
      questionnaire.min_question_score = -5
      questionnaire.max_question_score = 0
      expect(questionnaire).to be_valid
    end

    # Test ensures maximum score is greater than the minimum score
    it 'validate maximum score should be bigger than minimum score' do
      expect(questionnaire.min_question_score).to eq(0)
      questionnaire.min_question_score = 10
      expect(questionnaire).not_to be_valid
      questionnaire.min_question_score = 1
      expect(questionnaire).to be_valid
    end
  end

  describe '#minimum_score' do
    # Test validates minimum score of a questionnaire
    it 'validate minimum score' do
      questionnaire.min_question_score = 5
      expect(questionnaire.min_question_score).to eq(5)
    end

    # Test ensures minimum score is smaller than maximum score
    it 'validate minimum should be smaller than maximum' do
      expect(questionnaire.min_question_score).to eq(0)
      questionnaire.min_question_score = 10
      expect(questionnaire).not_to be_valid
      questionnaire.min_question_score = 0
    end

    # Test ensures minimum score is an integer
    it 'validate minimum score is integer' do
      expect(questionnaire.min_question_score).to eq(0)
      questionnaire.min_question_score = 'a'
      expect(questionnaire).not_to be_valid
    end

    # Min score is not required to be positive — negative min scores are valid
    it 'allows negative min_question_score when it is less than max' do
      questionnaire.min_question_score = -3
      expect(questionnaire).to be_valid
    end
  end

  describe 'associations' do
    # Test validates the association that a questionnaire comprises of several questions
    it 'has many questions' do
      expect(questionnaire.items).to include(question1, question2)
    end
  end

  describe '.copy' do
    # Test ensures creation of a copy of given questionnaire
    it 'creates a copy of the questionnaire' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied = Questionnaire.copy({ id: questionnaire.id, instructor_id: instructor.id })
      expect(copied.instructor_id).to eq(questionnaire.instructor_id)
      expect(copied.name).to eq("Copy of #{questionnaire.name}")
      expect(copied.created_at).to be_within(1.second).of(Time.zone.now)
    end

    # The copy must receive a new id and be a distinct persisted record
    it 'assigns a new id different from the original' do
      instructor.save!
      questionnaire.save!
      copied = Questionnaire.copy({ id: questionnaire.id, instructor_id: instructor.id })
      expect(copied.id).not_to eq(questionnaire.id)
      expect(copied.id).not_to be_nil
    end

    # Test ensures creation of copy of all the present questionnaire in the database
    it 'creates a copy of all questions belonging to the original questionnaire' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied = described_class.copy({ id: questionnaire.id, instructor_id: instructor.id })
      expect(copied.items.count).to eq(2)
      expect(copied.items.first.txt).to eq(question1.txt)
      expect(copied.items.second.txt).to eq(question2.txt)
    end

    # Copied items must be associated with the new questionnaire, not the original
    it 'associates copied items with the new questionnaire, not the original' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied = described_class.copy({ id: questionnaire.id, instructor_id: instructor.id })
      copied.items.each do |item|
        expect(item.questionnaire_id).to eq(copied.id)
        expect(item.questionnaire_id).not_to eq(questionnaire.id)
      end
    end

    # Item attributes are preserved on the copy
    it 'preserves item attributes on the copy' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied = described_class.copy({ id: questionnaire.id, instructor_id: instructor.id })
      first_copy = copied.items.first
      expect(first_copy.txt).to eq(question1.txt)
      expect(first_copy.weight).to eq(question1.weight)
      expect(first_copy.question_type).to eq(question1.question_type)
    end
  end
end
