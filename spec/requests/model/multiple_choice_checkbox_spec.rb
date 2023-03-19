require 'swagger_helper'

describe MultipleChoiceCheckbox do
  let(:multiple_choice_question) { MultipleChoiceCheckbox.new }
  let(:multiple_choice1) { QuizQuestionChoice.new }
  let(:multiple_choice2) { QuizQuestionChoice.new }
  let(:multiple_choice3) { QuizQuestionChoice.new }
  let(:multiple_choice4) { QuizQuestionChoice.new }
  before(:each) do
    multiple_choice_question.quiz_question_choices = [multiple_choice1, multiple_choice2, multiple_choice3, multiple_choice4]
    multiple_choice_question.txt = 'Question Text'
    allow(multiple_choice_question).to receive(:type).and_return('MultipleChoiceCheckbox')
    allow(multiple_choice1).to receive(:txt).and_return('Choice 1')
    allow(multiple_choice1).to receive(:iscorrect?).and_return(true)
    allow(multiple_choice2).to receive(:txt).and_return('Choice 2')
    allow(multiple_choice2).to receive(:iscorrect?).and_return(false)
    allow(multiple_choice3).to receive(:txt).and_return('Choice 3')
    allow(multiple_choice3).to receive(:iscorrect?).and_return(false)
    allow(multiple_choice4).to receive(:txt).and_return('Choice 4')
    allow(multiple_choice4).to receive(:iscorrect?).and_return(false)
  end
  describe '#isvalid' do
    context 'when there is only 1 correct answer' do
      it 'returns "A multiple-choice checkbox question should have more than one correct answer."' do
        questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: false } }
        expect(multiple_choice_question.isvalid(questions)).to eq('A multiple-choice checkbox question should have more than one correct answer.')
      end
    end
  end
  describe '#isvalid' do
    context 'when there is more than 1 correct answer' do
      it 'returns "valid"' do
        questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: true } }
        expect(multiple_choice_question.isvalid(questions)).to eq('valid')
      end
    end
  end
end
