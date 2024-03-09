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

    # Test ensures that a questionnaire is not deleted when it has questions associated
    it 'restricts deletion of questionnaire when it has associated questions' do
      instructor.save!
      questionnaire.save!
      question1.save!
      question2.save!
      expect { questionnaire.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
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
          # Test scenario 1
          # Given: There are assignments using the questionnaire
          # When: The delete method is called
          # Then: An error is raised with a message asking if the user wants to delete the assignment

          # Test scenario 2
          # Given: There are multiple assignments using the questionnaire
          # When: The delete method is called
          # Then: An error is raised for each assignment with a message asking if the user wants to delete the assignment
        end
      end

      context "when there are no assignments using the questionnaire" do
        it "deletes all the questions associated with the questionnaire" do
          # Test scenario 1
          # Given: There are no assignments using the questionnaire
          # When: The delete method is called
          # Then: All the questions associated with the questionnaire are deleted

          # Test scenario 2
          # Given: There are no assignments using the questionnaire and there are multiple questions
          # When: The delete method is called
          # Then: All the questions associated with the questionnaire are deleted
        end

        it "deletes the questionnaire node if it exists" do
          # Test scenario 1
          # Given: There are no assignments using the questionnaire and the questionnaire node exists
          # When: The delete method is called
          # Then: The questionnaire node is deleted

          # Test scenario 2
          # Given: There are no assignments using the questionnaire and the questionnaire node does not exist
          # When: The delete method is called
          # Then: No error is raised and the method completes successfully
        end

        it "deletes the questionnaire" do
          # Test scenario 1
          # Given: There are no assignments using the questionnaire
          # When: The delete method is called
          # Then: The questionnaire is deleted

          # Test scenario 2
          # Given: There are no assignments using the questionnaire and there are multiple questionnaires
          # When: The delete method is called
          # Then: The questionnaire is deleted
        end
      end
    end
end

=begin
   # Here are the skeleton rspec tests to be implemented as well, or to replace existing duplicate tests

   describe "#get_weighted_score" do
     context "when the assignment has a round" do
       it "computes the weighted score using the questionnaire symbol with the round appended" do
         # Test case 1
         # Given an assignment with an ID and a questionnaire with a symbol
         # And the questionnaire is used in a round
         # And a set of scores
         # When the get_weighted_score method is called with the assignment and scores
         # Then it should compute the weighted score using the questionnaire symbol with the round appended

         # Test case 2
         # Given an assignment with an ID and a questionnaire with a symbol
         # And the questionnaire is used in a round
         # And a different set of scores
         # When the get_weighted_score method is called with the assignment and scores
         # Then it should compute the weighted score using the questionnaire symbol with the round appended
       end
     end

     context "when the assignment does not have a round" do
       it "computes the weighted score using the questionnaire symbol" do
         # Test case 3
         # Given an assignment with an ID and a questionnaire with a symbol
         # And the questionnaire is not used in a round
         # And a set of scores
         # When the get_weighted_score method is called with the assignment and scores
         # Then it should compute the weighted score using the questionnaire symbol

         # Test case 4
         # Given an assignment with an ID and a questionnaire with a symbol
         # And the questionnaire is not used in a round
         # And a different set of scores
         # When the get_weighted_score method is called with the assignment and scores
         # Then it should compute the weighted score using the questionnaire symbol
       end
     end
   end
   describe "#compute_weighted_score" do
     context "when the average score is nil" do
       it "returns 0" do
         # Test scenario
       end
     end

     context "when the average score is not nil" do
       it "calculates the weighted score based on the questionnaire weight" do
         # Test scenario
       end
     end
   end
   describe "#true_false_questions?" do
     context "when there are true/false questions" do
       it "returns true" do
         # Test scenario 1: Multiple questions with type 'Checkbox'

         # Test scenario 2: Single question with type 'Checkbox'
       end
     end

     context "when there are no true/false questions" do
       it "returns false" do
         # Test scenario 1: Multiple questions with no 'Checkbox' type

         # Test scenario 2: Single question with no 'Checkbox' type
       end
     end
   end
   describe "#delete" do
     context "when there are assignments using the questionnaire" do
       it "raises an error with a message asking if the user wants to delete the assignment" do
         # Test scenario 1
         # Given: There are assignments using the questionnaire
         # When: The delete method is called
         # Then: An error is raised with a message asking if the user wants to delete the assignment

         # Test scenario 2
         # Given: There are multiple assignments using the questionnaire
         # When: The delete method is called
         # Then: An error is raised for each assignment with a message asking if the user wants to delete the assignment
       end
     end

     context "when there are no assignments using the questionnaire" do
       it "deletes all the questions associated with the questionnaire" do
         # Test scenario 1
         # Given: There are no assignments using the questionnaire
         # When: The delete method is called
         # Then: All the questions associated with the questionnaire are deleted

         # Test scenario 2
         # Given: There are no assignments using the questionnaire and there are multiple questions
         # When: The delete method is called
         # Then: All the questions associated with the questionnaire are deleted
       end

       it "deletes the questionnaire node if it exists" do
         # Test scenario 1
         # Given: There are no assignments using the questionnaire and the questionnaire node exists
         # When: The delete method is called
         # Then: The questionnaire node is deleted

         # Test scenario 2
         # Given: There are no assignments using the questionnaire and the questionnaire node does not exist
         # When: The delete method is called
         # Then: No error is raised and the method completes successfully
       end

       it "deletes the questionnaire" do
         # Test scenario 1
         # Given: There are no assignments using the questionnaire
         # When: The delete method is called
         # Then: The questionnaire is deleted

         # Test scenario 2
         # Given: There are no assignments using the questionnaire and there are multiple questionnaires
         # When: The delete method is called
         # Then: The questionnaire is deleted
       end
     end
   end
   describe "#max_possible_score" do
     context "when the questionnaire has no questions" do
       it "returns 0 as the maximum possible score" do
         # test code
       end
     end

     context "when the questionnaire has questions with different weights" do
       it "returns the correct maximum possible score based on the weights and max_question_score" do
         # test code
       end
     end

     context "when the questionnaire has questions with the same weight" do
       it "returns the correct maximum possible score based on the weight and max_question_score" do
         # test code
       end
     end

     context "when the questionnaire ID does not exist" do
       it "returns nil as the maximum possible score" do
         # test code
       end
     end
   end
   describe '.copy_questionnaire_details' do
     context 'when given valid parameters' do
       it 'creates a copy of the questionnaire with the instructor_id' do
         # Test body
       end

       it 'sets the name of the copied questionnaire as "Copy of [original name]"' do
         # Test body
       end

       it 'sets the created_at timestamp of the copied questionnaire to the current time' do
         # Test body
       end

       it 'saves the copied questionnaire' do
         # Test body
       end

       it 'creates copies of all the questions from the original questionnaire' do
         # Test body
       end

       it 'sets the questionnaire_id of the copied questions to the id of the copied questionnaire' do
         # Test body
       end

       it 'sets the size of the copied criterion and text response questions to "50,3" if size is nil' do
         # Test body
       end

       it 'saves the copied questions' do
         # Test body
       end

       it 'creates copies of all the question advices associated with the original questions' do
         # Test body
       end

       it 'sets the question_id of the copied question advices to the id of the copied question' do
         # Test body
       end

       it 'saves the copied question advices' do
         # Test body
       end

       it 'returns the copied questionnaire' do
         # Test body
       end
     end
   end
   describe "#validate_questionnaire" do
     context "when the maximum question score is less than 1" do
       it "should add an error message" do
         # test code
       end
     end

     context "when the minimum question score is less than 0" do
       it "should add an error message" do
         # test code
       end
     end

     context "when the minimum question score is greater than or equal to the maximum question score" do
       it "should add an error message" do
         # test code
       end
     end

     context "when a questionnaire with the same name and instructor already exists" do
       it "should add an error message" do
         # test code
       end
     end
   end
=end

end