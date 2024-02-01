require 'rails_helper'

RSpec.describe MultipleChoiceCheckbox, type: :model do
  let(:quiz_question) { create(:multiple_choice_checkbox) } # Assuming you have a factory for quiz questions

  describe '#edit' do
    it 'returns the correct JSON format' do
      expected_json = {
        id: quiz_question.id,
        txt: quiz_question.txt,
        question_type: quiz_question.question_type
        # Add other attributes you expect to include in the JSON
      }.to_json

      expect(quiz_question.edit).to eq(expected_json)
    end
  end

  describe '#complete' do
    it 'returns the correct JSON format' do
      # Create necessary QuizQuestionChoices for the test case
      # Replace this with appropriate FactoryBot or creation method as per your model setup
      create_list(:quiz_question_choice, 3, question: quiz_question)

      expected_json = {
        label: quiz_question.txt,
        choices: [
          { name: quiz_question.id.to_s, id: "#{quiz_question.id}_1", value: 'Choice 1', type: 'checkbox' },
          { name: quiz_question.id.to_s, id: "#{quiz_question.id}_2", value: 'Choice 2', type: 'checkbox' },
          { name: quiz_question.id.to_s, id: "#{quiz_question.id}_3", value: 'Choice 3', type: 'checkbox' }
        # Update 'value' as per your QuizQuestionChoice attributes
        ]
      }.to_json

      expect(quiz_question.complete).to eq(expected_json)
    end
  end

  describe '#view_completed_question' do
    it 'returns the correct JSON format' do
      # Create necessary QuizQuestionChoices for the test case
      # Replace this with appropriate FactoryBot or creation method as per your model setup
      create_list(:quiz_question_choice, 2, question: quiz_question, correct: true)
      create_list(:quiz_question_choice, 1, question: quiz_question, correct: false)

      user_answer = [double('UserAnswer', answer: 1, comments: 'Comment 1'), double('UserAnswer', answer: 0, comments: 'Comment 2')]

      expected_json = {
        answers: [
          { text: 'Choice 1', correctness: 'Correct' },
          { text: 'Choice 2' },
        # Add more choices as per your test data
        ],
        user_answer: {
          answer: '<img src="/assets/Check-icon.png"/>',
          comments: ['Comment 1', 'Comment 2']
        }
      }.to_json

      expect(quiz_question.view_completed_question(user_answer)).to eq(expected_json)
    end
  end

  describe '#is_valid' do
    it 'returns a valid message' do
      choice_info = {
        '1': { txt: 'Choice 1', correct: true },
        '2': { txt: '', correct: false }
        # Add more choices as per your test data
      }

      expect(quiz_question.is_valid(choice_info)).to eq('Please make sure every option has text for all options.')
    end

    it 'returns a message for no correct answer' do
      choice_info = {
        '1': { txt: 'Choice 1', correct: false },
        '2': { txt: 'Choice 2', correct: false }
        # Add more choices as per your test data
      }

      expect(quiz_question.is_valid(choice_info)).to eq('Please select a correct answer for all questions.')
    end

    it 'returns a message for only one correct answer' do
      choice_info = {
        '1': { txt: 'Choice 1', correct: true },
        '2': { txt: 'Choice 2', correct: false },
        '3': { txt: 'Choice 3', correct: false }
        # Add more choices as per your test data
      }

      expect(quiz_question.is_valid(choice_info)).to eq('A multiple-choice checkbox question should have more than one correct answer.')
    end
  end
end
