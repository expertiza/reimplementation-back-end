require 'rails_helper'

describe Questionnaire, type: :model do
  # Creating dummy objects for the test with the help of let statement
  let(:role) {Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil)}
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:questionnaire) { FactoryBot.build(:questionnaire, { id: 1, name: 'abc', instructor_id: instructor.id }) }
  let(:questionnaire1) { FactoryBot.build(:questionnaire, { id: 2, name: 'xyz', max_question_score: 20, instructor_id: instructor.id }) }
  let(:questionnaire3) { FactoryBot.build(:review_questionnaire, { id: 3, name: 'pqr', instructor_id: instructor.id }) }
  let(:question1) { questionnaire.questions.build(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "Scale", break_before: true) }
  let(:question2) { questionnaire.questions.build(weight: 10, id: 2, seq: 2, txt: "que 2", question_type: "Checkbox", break_before: true) }


  describe '#name' do
    # Test validates the name of the questionnaire
    it 'returns the name of the Questionnaire' do
      # Act Assert
      expect(questionnaire.name).to eq('abc')
      expect(questionnaire1.name).to eq('xyz')
      expect(questionnaire3.name).to eq('pqr')
    end

    # Test ensures that the name field of the questionnaire is not blank
    it 'Validate presence of name which cannot be blank' do
      # Arrange
      questionnaire.name = '  '

      # Act Assert
      expect(questionnaire).not_to be_valid
    end

    # Test ensures that the name field of the questionnaire is unique per instructor
    it 'Validate name field must be unique per instructor' do
      # Arrange Act
      questionnaire.save!
      questionnaire1.name = questionnaire.name
      questionnaire3.name = questionnaire.name
      instructor2 = Instructor.create(name: 'testinstructortwo', email: 'test2@test.com', full_name: 'Test Instructor 2', password: '123456', role: role)
      instructor2.save!
      questionnaire3.instructor_id = instructor2.id
      # Assert
      expect(questionnaire).to be_valid
      expect(questionnaire1).not_to be_valid
      expect(questionnaire3).to be_valid
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
      questionnaire.max_question_score = 1.1
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

      expect(questionnaire).to be_valid
      questionnaire.max_question_score = 0
      expect(questionnaire).not_to be_valid
      questionnaire.max_question_score = 2
      questionnaire.min_question_score = 3
      expect(questionnaire).not_to be_valid
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
      expect(questionnaire.questions).to include(question1, question2)
    end
  end

  describe '.copy_questionnaire_details' do
# Test ensures calls from the method copy_questionnaire_details
    it 'allowing calls from copy_questionnaire_details' do
      allow(Questionnaire).to receive(:find).with('1').and_return(questionnaire)
      allow(Question).to receive(:where).with(questionnaire_id: '1').and_return([Question])
    end

    # Test ensures creation of a copy of given questionnaire
    it 'creates a copy of the questionnaire' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      copied_questionnaire = Questionnaire.copy_questionnaire_details( { id: questionnaire.id})
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
      copied_questionnaire = described_class.copy_questionnaire_details({ id: questionnaire.id })
      expect(copied_questionnaire.questions.count).to eq(2)
      expect(copied_questionnaire.questions.first.txt).to eq(question1.txt)
      expect(copied_questionnaire.questions.second.txt).to eq(question2.txt)
    end
  end

  # This is the beginning of the skeleton implementation
  describe '#get_weighted_score' do
    before :each do
      @questionnaire = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
      @assignment = FactoryBot.create(:assignment)
    end
    context 'when the assignment has a round' do
      it 'computes the weighted score using the questionnaire symbol with the round appended' do
        # Test case 1
        # Arrange
        FactoryBot.create(:assignment_questionnaire, { assignment_id: @assignment.id, questionnaire_id: @questionnaire.id, used_in_round: 1 })
        scores = { "#{@questionnaire.symbol}#{1}".to_sym => { scores: { avg: 100 } } }
        # Act Assert
        expect(@questionnaire.get_weighted_score(@assignment, scores)).to eq(100)
        # Test case 2
        # Arrange
        scores = { "#{@questionnaire.symbol}#{1}".to_sym => { scores: { avg: 75 } } }
        # Act Assert
        expect(@questionnaire.get_weighted_score(@assignment, scores)).to eq(75)
      end
    end

    context 'when the assignment does not have a round' do
      it 'computes the weighted score using the questionnaire symbol' do
        # Test case 3
        # Arrange
        FactoryBot.create(:assignment_questionnaire, { assignment_id: @assignment.id, questionnaire_id: @questionnaire.id })
        scores = { @questionnaire.symbol => { scores: { avg: 100 } } }
        # Act Assert
        expect(@questionnaire.get_weighted_score(@assignment, scores)).to eq(100)
        # Test case 4
        # Arrange
        scores = { @questionnaire.symbol => { scores: { avg: 75 } } }
        # Act Assert
        expect(@questionnaire.get_weighted_score(@assignment, scores)).to eq(75)
      end
    end
    describe "#compute_weighted_score" do
      before :each do
        @questionnaire = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        @assignment = FactoryBot.create(:assignment)
        FactoryBot.create(:assignment_questionnaire, { assignment_id: @assignment.id, questionnaire_id: @questionnaire.id, questionnaire_weight: 50 })
      end
      context "when the average score is nil" do
        it "returns 0" do
          # Test scenario
          # Arrange
          scores = { @questionnaire.symbol => { scores: { avg: nil } } }

          # Act Assert
          expect(@questionnaire.compute_weighted_score(@questionnaire.symbol, @assignment, scores)).to eq(0)
        end
      end
      context "when the average score is not nil" do
        it "calculates the weighted score based on the questionnaire weight" do
          # Test scenario
          # Arrange
          scores = { @questionnaire.symbol => { scores: { avg: 75 } } }

          # Act Assert
          expect(@questionnaire.compute_weighted_score(@questionnaire.symbol, @assignment, scores)).to eq(75 * 0.5)
        end
      end
    end
  end
  describe "#true_false_questions?" do
    before :each do
      @questionnaire = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
    end
    context "when there are true/false questions" do
      it "returns true" do
        # Test scenario 2: Single question with type 'Checkbox'
        # Arrange
        @questionnaire.questions.create(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "Checkbox", break_before: true)

        # Act Assert
        expect(@questionnaire.true_false_questions?).to eq(true)

        # Test scenario 1: Multiple questions with type 'Checkbox'
        # Arrange
        @questionnaire.questions.create(weight: 1, id: 2, seq: 1, txt: "que 1", question_type: "Checkbox", break_before: true)
        @questionnaire.questions.create(weight: 1, id: 3, seq: 1, txt: "que 1", question_type: "Checkbox", break_before: true)

        # Act Assert
        expect(@questionnaire.true_false_questions?).to eq(true)
      end
    end

    context "when there are no true/false questions" do
      it "returns false" do
        # Test scenario 2: Single question with no 'Checkbox' type
        # Arrange
        @questionnaire.questions.create(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)

        # Act Assert
        expect(@questionnaire.true_false_questions?).to eq(false)

        # Test scenario 1: Multiple questions with no 'Checkbox' type
        # Arrange
        @questionnaire.questions.create(weight: 1, id: 2, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)
        @questionnaire.questions.create(weight: 1, id: 3, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)

        # Act Assert
        expect(@questionnaire.true_false_questions?).to eq(false)
      end
    end
  end
  describe "#delete" do
    context "when there are assignments using the questionnaire" do
      it "raises an error with a message asking if the user wants to delete the assignment" do
        # Arrange
        questionnaire_single_assignment = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        single_assignment = FactoryBot.create(:assignment)
        FactoryBot.create(:assignment_questionnaire, { assignment_id: single_assignment.id, questionnaire_id: questionnaire_single_assignment.id})
        questionnaire_multi_assignment = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        multi_assignment1 = FactoryBot.create(:assignment)
        FactoryBot.create(:assignment_questionnaire, { assignment_id: multi_assignment1.id, questionnaire_id: questionnaire_multi_assignment.id})
        multi_assignment2 = FactoryBot.create(:assignment)
        FactoryBot.create(:assignment_questionnaire, { assignment_id: multi_assignment2.id, questionnaire_id: questionnaire_multi_assignment.id})

        # Test scenario 1
        # Given: There are assignments using the questionnaire
        # When: The delete method is called
        # Then: An error is raised with a message asking if the user wants to delete the assignment
        expect { questionnaire_single_assignment.delete }.to raise_exception(RuntimeError) do |error|
          expect(error.message).to match(/^The assignment .* uses this questionnaire/)
        end

        # Test scenario 2
        assignment1_pattern = /^The assignment #{Regexp.escape(multi_assignment1.name)} uses this questionnaire/
        assignment2_pattern = /^The assignment #{Regexp.escape(multi_assignment2.name)} uses this questionnaire/
        # Given: There are multiple assignments using the questionnaire
        # When: The delete method is called
        # Then: An error is raised for each assignment with a message asking if the user wants to delete the assignment
        expect { questionnaire_multi_assignment.delete }.to raise_exception(RuntimeError) do |error|
          expect(error.message).to match(assignment1_pattern)
        end
        multi_assignment1.destroy!
        expect { questionnaire_multi_assignment.delete }.to raise_exception(RuntimeError) do |error|
          expect(error.message).to match(assignment2_pattern)
        end
      end
    end

    context "when there are no assignments using the questionnaire" do
      it "deletes all the questions associated with the questionnaire" do
        # Test scenario 1
        # Given: There are no assignments using the questionnaire
        # When: The delete method is called
        # Then: All the questions associated with the questionnaire are deleted
        # Arrange
        questionnaire_one_question = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        question1 = questionnaire_one_question.questions.build(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)
        question1.save!

        # Act
        questionnaire_one_question.delete

        # Assert
        expect(Question.find_by(id: question1.id)).to be_nil

        # Test scenario 2
        # Given: There are no assignments using the questionnaire and there are multiple questions
        # When: The delete method is called
        # Then: All the questions associated with the questionnaire are deleted
        # Arrange
        questionnaire_multi_question = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        question1 = questionnaire_multi_question.questions.build(weight: 1, id: 1, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)
        question1.save!
        question2 = questionnaire_multi_question.questions.build(weight: 1, id: 2, seq: 1, txt: "que 1", question_type: "Scale", break_before: true)
        question2.save!

        # Act
        questionnaire_multi_question.delete

        # Assert
        expect(Question.find_by(id: question1.id)).to be_nil
        expect(Question.find_by(id: question2.id)).to be_nil
      end

      it "deletes the questionnaire node if it exists" do
        # Test scenario 1
        # Given: There are no assignments using the questionnaire and the questionnaire node exists
        # When: The delete method is called
        # Then: The questionnaire node is deleted
        questionnaire = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })
        q_node = QuestionnaireNode.create(parent_id: 0, node_object_id: questionnaire.id, type: 'QuestionnaireNode')
        # Act
        questionnaire.delete

        # Assert
        expect(QuestionnaireNode.find_by(id: q_node.id)).to be_nil

        # Test scenario 2
        # Given: There are no assignments using the questionnaire and the questionnaire node does not exist
        # When: The delete method is called
        # Then: No error is raised and the method completes successfully
        questionnaire = FactoryBot.create(:review_questionnaire, { instructor_id: instructor.id })

        # Act Assert
        expect { questionnaire.delete }.not_to raise_error
        expect(Questionnaire.find_by(id: questionnaire.id)).to be_nil
      end

      # The below tests were redundant
      # it "deletes the questionnaire" do
        # Test scenario 1
        # Given: There are no assignments using the questionnaire
        # When: The delete method is called
        # Then: The questionnaire is deleted

        # Test scenario 2
        # Given: There are no assignments using the questionnaire and there are multiple questionnaires
        # When: The delete method is called
        # Then: The questionnaire is deleted
        # end
    end
  end

  describe '#name_is_unique' do
    context 'when no other questionnaire with the same name exists for the same instructor' do
      it 'does not add error' do
        questionnaire.name_is_unique
        expect(questionnaire.errors[:name]).to_not include('must be unique')
      end
    end

    context 'when two questionnaires with the same name exists for the same instructor' do
      it 'adds error' do
        existing_questionnaire = FactoryBot.create(:questionnaire, instructor: instructor)
        duplicate_question = FactoryBot.create(:questionnaire, instructor: instructor)
        duplicate_question.name_is_unique
        expect(duplicate_question.errors[:name]).to include('must be unique')
      end
    end

    context 'when two questionnaires have the same name for different instructors' do
      it 'does not throw an error' do
        ## Creating a different instructor for this test.
        instructor2 = Instructor.create(name: 'testinstructortwo', email: 'test2@test.com', full_name: 'Test Instructor 2', password: '123456', role: role)

        original_questionnaire = FactoryBot.create(:questionnaire, instructor: instructor)
        new_questionnaire = FactoryBot.create(:questionnaire, instructor: instructor2)
        new_questionnaire.name_is_unique
        expect(new_questionnaire.errors[:name]).to_not include('must be unique')
      end
    end

    context 'when two questionnaires have different names for the same instructor' do
      it 'does not throw an error' do
        original_questionnaire = FactoryBot.create(:questionnaire, instructor: instructor)
        new_questionnaire = FactoryBot.create(:questionnaire, instructor: instructor, name: "Super cool new questionnaire")

        new_questionnaire.name_is_unique
        expect(new_questionnaire.errors[:name]).to_not include('must be unique')
      end
    end

    context 'when any of the required values is missing' do
      it 'returns nothing if id is nil' do
        questionnaire.id = nil
        result = questionnaire.name_is_unique
        expect(result).to be_nil
      end

      it 'returns nothing if name is nil' do
        questionnaire.name = nil
        result = questionnaire.name_is_unique
        expect(result).to be_nil
      end

      it 'returns nothing if instructor_id is nil' do
        questionnaire.instructor_id = nil
        result = questionnaire.name_is_unique
        expect(result).to be_nil
      end
    end
  end

  describe '#min_less_than_max' do
    context 'when either value is not there' do
      it 'returns nil if min_score is nil.' do
        questionnaire = FactoryBot.create( :questionnaire, instructor: instructor)
        ## Must be added here or it will not pass validation when being created.
        questionnaire.min_question_score = nil
        result = questionnaire.min_less_than_max
        expect(result).to be_nil
      end
    end
    it 'returns nil if max_score is nil.' do
      questionnaire = FactoryBot.create( :questionnaire, instructor: instructor)
      ## Must be added here or it will not pass validation when being created.
      questionnaire.max_question_score = nil
      result = questionnaire.min_less_than_max
      expect(result).to be_nil
    end
    context 'when it is given two integers' do
      it 'adds an error if min is greater than max' do
        questionnaire = FactoryBot.create( :questionnaire, instructor: instructor)
        questionnaire.max_question_score = 20
        questionnaire.min_question_score = 25 ## min is now greater than max.
        questionnaire.min_less_than_max
        expect(questionnaire.errors[:min_question_score]).to include('must be less than max question score')
      end
      it 'adds an error if min is equal to max' do
        questionnaire = FactoryBot.create( :questionnaire, instructor: instructor)
        questionnaire.max_question_score = 25
        questionnaire.min_question_score = 25 ## min is now equal to max.
        questionnaire.min_less_than_max
        expect(questionnaire.errors[:min_question_score]).to include('must be less than max question score')
      end

      it 'does not add an error if min is less than max' do
        questionnaire = FactoryBot.create( :questionnaire, instructor: instructor)
        questionnaire.max_question_score = 25
        questionnaire.min_question_score = 20 ## min is now less than max.
        questionnaire.min_less_than_max
        expect(questionnaire.errors[:min_question_score]).to be_empty
      end
    end
  end

end