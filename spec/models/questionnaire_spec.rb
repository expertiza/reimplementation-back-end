# frozen_string_literal: true

require 'rails_helper'
describe Questionnaire, type: :model do

  # Creating dummy objects for the test with the help of let statement
  let(:role) {Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil)}
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role_id: role.id) }
  let(:questionnaire) do
    Questionnaire.create!(
      id: 1,
      name: 'abc',
      private: false,
      min_question_score: 0,
      max_question_score: 10,
      instructor: instructor,
    )
  end
  let(:questionnaire1) { Questionnaire.new name: 'xyz', private: 0, max_question_score: 20, instructor_id: instructor.id }
  let(:questionnaire2) { Questionnaire.new name: 'pqr', private: 0, max_question_score: 10, instructor_id: instructor.id }
  let(:question1) { questionnaire.items.build(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "scale", break_before: true) }
  let(:question2) { questionnaire.items.build(weight: 10, id: 2, seq: 2, txt: "que 2", question_type: "multiple_choice", break_before: true) }



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
      expect(questionnaire.items).to include(question1, question2)
    end
  end

  describe '.copy_questionnaire_details' do
    # Test ensures calls from the method copy_questionnaire_details
    it 'allowing calls from copy_questionnaire_details' do
      allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
      allow(Item).to receive(:where).with(questionnaire_id: '1').and_return([Item])
    end
    
    # Test ensures creation of a copy of given questionnaire
    it 'creates a copy of the questionnaire' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied_questionnaire = Questionnaire.copy_questionnaire_details( { id: questionnaire.id, instructor_id: instructor.id})
      expect(copied_questionnaire.instructor_id).to eq(questionnaire.instructor_id)
      expect(copied_questionnaire.name).to eq("Copy of #{questionnaire.name}")
      expect(copied_questionnaire.created_at).to be_within(1.second).of(Time.zone.now)
    end

    # Test ensures creation of copy of all the present questionnaire in the database
    it 'creates a copy of all questions belonging to the original questionnaire' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied_questionnaire = described_class.copy_questionnaire_details({ id: questionnaire.id, instructor_id: instructor.id })
      expect(copied_questionnaire.items.count).to eq(2)
      expect(copied_questionnaire.items.first.txt).to eq(question1.txt)
      expect(copied_questionnaire.items.second.txt).to eq(question2.txt)
    end
  end

  describe '.accessible_for_assignment' do
    let!(:assignment_instructor_user) { create(:user, :instructor) }
    let!(:assignment_instructor) { Instructor.find(assignment_instructor_user.id) }
    let!(:other_instructor_user) { create(:user, :instructor) }
    let!(:other_instructor) { Instructor.find(other_instructor_user.id) }
    let!(:ta_user) { create(:user, :ta) }
    let!(:course) { create(:course, instructor: assignment_instructor) }
    let!(:assignment) { create(:assignment, instructor: assignment_instructor, course: course) }
    let!(:public_review_rubric) do
      create(:questionnaire,
             instructor: assignment_instructor,
             questionnaire_type: 'ReviewQuestionnaire',
             name: 'Public review rubric',
             private: false)
    end
    let!(:private_assignment_rubric) do
      create(:questionnaire,
             instructor: assignment_instructor,
             questionnaire_type: 'ReviewQuestionnaire',
             name: 'Instructor private rubric',
             private: true)
    end
    let!(:private_other_rubric) do
      create(:questionnaire,
             instructor: other_instructor,
             questionnaire_type: 'ReviewQuestionnaire',
             name: 'Other private rubric',
             private: true)
    end
    let!(:public_non_review_rubric) do
      create(:questionnaire,
             instructor: assignment_instructor,
             questionnaire_type: 'MetareviewQuestionnaire',
             name: 'Public metareview rubric',
             private: false)
    end

    it 'returns only public rubrics of the requested type when user is nil' do
      rubrics = described_class.accessible_for_assignment(
        user: nil,
        assignment: assignment,
        questionnaire_type: 'ReviewQuestionnaire'
      )

      expect(rubrics).to match_array([public_review_rubric])
    end

    it 'includes assignment instructor private rubrics for the assignment instructor' do
      rubrics = described_class.accessible_for_assignment(
        user: assignment_instructor,
        assignment: assignment,
        questionnaire_type: 'ReviewQuestionnaire'
      )

      expect(rubrics).to include(public_review_rubric, private_assignment_rubric)
      expect(rubrics).not_to include(private_other_rubric, public_non_review_rubric)
    end

    it 'includes assignment instructor private rubrics for a mapped TA' do
      TaMapping.create!(course: course, user_id: ta_user.id)

      rubrics = described_class.accessible_for_assignment(
        user: ta_user,
        assignment: assignment,
        questionnaire_type: 'ReviewQuestionnaire'
      )

      expect(rubrics).to include(public_review_rubric, private_assignment_rubric)
      expect(rubrics).not_to include(private_other_rubric, public_non_review_rubric)
    end
  end

end