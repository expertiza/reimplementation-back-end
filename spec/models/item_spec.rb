require 'rails_helper'

RSpec.describe Item, type: :model do
  # Creating dummy objects for the test with the help of let statement
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) do
    Instructor.create(id: 1234, name: 'testinstructor', email: 'test@test.com', fullname: 'Test Instructor',
                      password: '123456', role:)
  end
  let(:questionnaire) do
    Questionnaire.new id: 1, name: 'abc', private: 0, min_question_score: 0, max_question_score: 10,
                      instructor_id: instructor.id
  end

  describe 'validations' do
    # Test validates that question has valid attributes
    it 'is valid with valid attributes' do
      question = Item.new(seq: 1, txt: 'Sample question', question_type: 'multiple_choice', break_before: true,
                              questionnaire:)
      expect(question).to be_valid
    end

    # Test ensures that a question is not valid without seq field
    it 'is not valid without a seq' do
      question = Item.new(txt: 'Sample question', question_type: 'multiple_choice', break_before: true,
                              questionnaire:)
      expect(question).to_not be_valid
    end

    # Test ensures that seq field is numeric
    it 'is not valid with a non-numeric seq' do
      question = Item.new(seq: 'one', txt: 'Sample question', question_type: 'multiple_choice',
                              break_before: true, questionnaire:)
      expect(question).to_not be_valid
    end

    # Test ensures that a question is not valid without txt field
    it 'is not valid without a txt' do
      question = Item.new(seq: 1, question_type: 'multiple_choice', break_before: true,
                              questionnaire:)
      expect(question).to_not be_valid
    end

    # Test ensures that a question is not valid without question_type field
    it 'is not valid without a question_type' do
      question = Item.new(seq: 1, txt: 'Sample question', break_before: true, questionnaire:)
      expect(question).to_not be_valid
    end

    # Test ensures that a question is not valid without break_before field
    it 'is not valid without a break_before value' do
      question = Item.new(seq: 1, txt: 'Sample question', question_type: 'multiple_choice',
                              questionnaire:)
      expect(question).to_not be_valid
    end

    # Test ensures that a question does not exist without a questionnaire
    it 'is not valid without a questionnaire' do
      question = Item.new(seq: 1, txt: 'Sample question', question_type: 'multiple_choice', break_before: true)
      expect(question).to_not be_valid
    end
  end

  describe '#delete' do
    # Test ensures that a question object is deleted properly taking all its association into consideration
    it 'destroys the question object' do
      instructor.save!
      questionnaire.save!
      question = Item.create(seq: 1, txt: 'Sample question', question_type: 'multiple_choice',
                                 break_before: true, questionnaire:)
      expect { question.delete }.to change { Item.count }.by(-1)
    end
  end

  describe '#set_choice_strategy' do
    context 'when the question type is Dropdown' do
      let(:item) { create(:item, questionnaire: questionnaire, question_type: 'Dropdown') }

      it 'assigns the correct strategy' do
        item.set_choice_strategy
        expect(item.choice_strategy).to be_an_instance_of(Strategies::DropdownStrategy)
      end
    end

    context 'when the question type is MultipleChoice' do
      let(:item) { create(:item, questionnaire: questionnaire, question_type: 'MultipleChoice') }

      it 'assigns the correct strategy' do
        item.set_choice_strategy
        expect(item.choice_strategy).to be_an_instance_of(Strategies::MultipleChoiceStrategy)
      end
    end

    context 'when the question type is Scale' do
      let(:item) { create(:item, questionnaire: questionnaire, question_type: 'Scale') }

      it 'assigns the correct strategy' do
        item.set_choice_strategy
        expect(item.choice_strategy).to be_an_instance_of(Strategies::ScaleStrategy)
      end
    end

    context 'when the question type is unknown' do
      let(:item) { create(:item, questionnaire: questionnaire, question_type: 'Unknown') }

      it 'raises an error' do
        expect { item.set_choice_strategy }.to raise_error("Unknown question type: Unknown")
      end
    end
  end
end
