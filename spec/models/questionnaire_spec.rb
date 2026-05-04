# frozen_string_literal: true

require 'rails_helper'
describe Questionnaire, type: :model do
  # Creating dummy objects for the test with the help of let statement
  before do
    allow_any_instance_of(User).to receive(:set_defaults)
  end
  let(:instructor) { create(:instructor) }
  let(:questionnaire) do
        create(:questionnaire,
          name: 'abc',
          private: false,
          min_question_score: 0,
          max_question_score: 10,
          instructor: instructor)
  end
  let(:questionnaire1) do
    build(:questionnaire, name: 'xyz', private: 0, max_question_score: 20, instructor: instructor)
  end
  let(:questionnaire2) do
    build(:questionnaire, name: 'pqr', private: 0, max_question_score: 10, instructor: instructor)
  end
  let(:question1) do
    create(:item, questionnaire: questionnaire, weight: 1, seq: 1, txt: 'que 1', question_type: 'scale')
  end
  let(:question2) do
    create(:item, questionnaire: questionnaire, weight: 10, seq: 2, txt: 'que 2', question_type: 'multiple_choice')
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

    # Test ensures maximum score is positive
    it 'validate maximum score should be positive' do
      expect(questionnaire.max_question_score).to eq(10)
      questionnaire.max_question_score = -10
      expect(questionnaire).not_to be_valid
      questionnaire.max_question_score = 0
      expect(questionnaire).not_to be_valid
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
  end

  describe 'associations' do
    # Test validates the association that a questionnaire comprises of several questions
    it 'has many questions' do
      question1
      question2
      expect(questionnaire.items.reload).to include(question1, question2)
    end
  end

  describe '.copy_questionnaire_details' do
    # Test ensures calls from the method copy_questionnaire_details
    it 'allowing calls from copy_questionnaire_details' do
      allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
      allow(Item).to receive(:where).with(questionnaire_id: '1').and_return([question1, question2])
    end

    # Test ensures creation of a copy of given questionnaire
    it 'creates a copy of the questionnaire' do
      question1
      question2
      copied_questionnaire = Questionnaire.copy_questionnaire_details({ id: questionnaire.id,
                            instructor_id: instructor.id })
      expect(copied_questionnaire.instructor_id).to eq(questionnaire.instructor_id)
      expect(copied_questionnaire.name).to eq("Copy of #{questionnaire.name}")
      expect(copied_questionnaire.created_at).to be_within(1.second).of(Time.zone.now)
    end

    # Test ensures creation of copy of all the present questionnaire in the database
    it 'creates a copy of all questions belonging to the original questionnaire' do
      question1
      question2
      copied_questionnaire = described_class.copy_questionnaire_details({ id: questionnaire.id,
                              instructor_id: instructor.id })
      expect(copied_questionnaire.items.count).to eq(2)
      expect(copied_questionnaire.items.first.txt).to eq(question1.txt)
      expect(copied_questionnaire.items.second.txt).to eq(question2.txt)
    end

    # Ensures advice rows are duplicated along with copied questions.
    it 'copies advice rows when original question has advice' do
      question1
      QuestionAdvice.insert(
        {
          question_id: question1.id,
          score: 3,
          advice: 'Good rationale',
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      )

      copied_questionnaire = described_class.copy_questionnaire_details({ id: questionnaire.id,
                              instructor_id: instructor.id })
      copied_question = copied_questionnaire.items.first

      copied_advice = QuestionAdvice.where(question_id: copied_question.id)
      expect(copied_advice.count).to eq(1)
      expect(copied_advice.first.score).to eq(3)
      expect(copied_advice.first.advice).to eq('Good rationale')
    end
  end

  describe '#symbol' do
    # Confirms the questionnaire symbol reflects the review type.
    it 'returns review symbol' do
      expect(questionnaire.symbol).to eq(:review)
    end
  end

  describe '#get_assessments_for' do
    # Verifies assessments are proxied from the participant reviews collection.
    it 'returns participant reviews' do
      reviews = [double('review1'), double('review2')]
      participant = double('participant', reviews: reviews)
      expect(questionnaire.get_assessments_for(participant)).to eq(reviews)
    end
  end

  describe '#check_for_question_associations' do
    # Prevents deletion when the questionnaire still has items.
    it 'raises delete restriction when items exist' do
      question1
      questionnaire.items.reload
      expect { questionnaire.check_for_question_associations }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    # Allows deletion when there are no associated items.
    it 'does not raise when no items exist' do
      questionnaire
      expect { questionnaire.check_for_question_associations }.not_to raise_error
    end
  end

  describe '#as_json' do
    # Ensures JSON serialization includes the instructor field.
    it 'returns serialized hash with instructor key' do
      json = questionnaire.as_json
      expect(json).to include('id', 'name', 'instructor')
    end
  end

  describe '#get_weighted_score' do
    let(:assignment) { double('assignment', id: 42) }

    # Uses the base symbol when no round-specific questionnaire is set.
    it 'uses base symbol when used_in_round is nil' do
      aq = double('assignment_questionnaire', used_in_round: nil)
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 42,
                                                               questionnaire_id: questionnaire.id).and_return(aq)
      expect(questionnaire).to receive(:compute_weighted_score).with(:review, assignment, {})
      questionnaire.get_weighted_score(assignment, {})
    end

    # Uses a round-specific symbol when used_in_round is provided.
    it 'uses round specific symbol when used_in_round is present' do
      aq = double('assignment_questionnaire', used_in_round: 2)
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 42,
                                                               questionnaire_id: questionnaire.id).and_return(aq)
      expect(questionnaire).to receive(:compute_weighted_score).with(:review2, assignment, {})
      questionnaire.get_weighted_score(assignment, {})
    end
  end

  describe '#compute_weighted_score' do
    let(:assignment) { double('assignment', id: 77) }

    # Handles missing averages by returning zero.
    it 'returns 0 when average score is nil' do
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 77).and_return(double('aq',
                                                                                                    questionnaire_weight: 25))
      scores = { review: { scores: { avg: nil } } }
      expect(questionnaire.compute_weighted_score(:review, assignment, scores)).to eq(0)
    end

    # Computes weighted average when an average score is present.
    it 'returns weighted average when avg exists' do
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 77).and_return(double('aq',
                                                                                                    questionnaire_weight: 25))
      scores = { review: { scores: { avg: 8 } } }
      expect(questionnaire.compute_weighted_score(:review, assignment, scores)).to eq(2.0)
    end
  end

  describe '#true_false_items?' do
    # Detects checkbox items as true/false questions.
    it 'returns true when a checkbox item is present' do
      allow(questionnaire).to receive(:items).and_return([double('item', type: 'Checkbox')])
      expect(questionnaire.true_false_items?).to be(true)
    end

    # Returns false when no checkbox items exist.
    it 'returns false when no checkbox item is present' do
      allow(questionnaire).to receive(:items).and_return([double('item', type: 'Criterion')])
      expect(questionnaire.true_false_items?).to be(false)
    end
  end

  describe '#max_possible_score' do
    # Calculates max possible score from weights and max score.
    it 'returns sum of item weights multiplied by max_question_score' do
      question1
      question2

      expect(questionnaire.max_possible_score.to_i).to eq(110)
    end
  end
end
