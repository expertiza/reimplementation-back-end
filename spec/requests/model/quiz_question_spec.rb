require 'swagger_helper'

describe QuizQuestion do
  let(:quiz_question) { QuizQuestion.new }
  let(:quiz_question_choice1) { QuizQuestionChoice.new }
  let(:quiz_question_choice2) { QuizQuestionChoice.new }
  let(:quiz_question_choice3) { QuizQuestionChoice.new }
  let(:quiz_question_choice4) { QuizQuestionChoice.new }
  before(:each) do
    quiz_question.quiz_question_choices = [quiz_question_choice1, quiz_question_choice2, quiz_question_choice3, quiz_question_choice4]
    quiz_question.txt = 'Question Text'
    allow(quiz_question).to receive(:type).and_return('MultipleChoiceRadio')
    allow(quiz_question_choice1).to receive(:txt).and_return('Choice 1')
    allow(quiz_question_choice1).to receive(:iscorrect?).and_return(true)
    allow(quiz_question_choice2).to receive(:txt).and_return('Choice 2')
    allow(quiz_question_choice2).to receive(:iscorrect?).and_return(false)
    allow(quiz_question_choice3).to receive(:txt).and_return('Choice 3')
    allow(quiz_question_choice3).to receive(:iscorrect?).and_return(false)
    allow(quiz_question_choice4).to receive(:txt).and_return('Choice 4')
    allow(quiz_question_choice4).to receive(:iscorrect?).and_return(false)
  end
  describe '#view_question_text' do
    it 'returns the text of the questions' do
      expect(quiz_question.view_question_text).to eq('<b>Question Text</b><br />Question Type: MultipleChoiceRadio<br />Question Weight: <br />  - <b>Choice 1</b><br />   - Choice 2<br />   - Choice 3<br />   - Choice 4<br /> <br />')
    end
  end
  describe '#get_formatted_question_type' do
    it 'returns the type' do
      expect(quiz_question.get_formatted_question_type).to eq('Multiple Choice - Radio')
    end
  end
  describe '#isvalid' do
    context 'when the question and its choices have valid text' do
      it 'returns "valid"' do
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: 'question text', iscorrect: '1' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        expect(quiz_question.isvalid(questions)).to eq('valid')
      end
    end
  end
  describe '#isvaid' do
    let(:no_text_question) {QuizQuestion.new}
    context 'when the question itself does not have txt' do
      it 'returns "Please make sure all questions have text"' do
        allow(no_text_question).to receive(:txt).and_return('')
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: 'question text', iscorrect: '1' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        expect(no_text_question.isvalid(questions)).to eq('Please make sure all questions have text')
      end
    end
  end
  describe '#isvalid' do
    context 'when a choice does not have text' do
      it 'returns "Please make sure every question has text for all options"' do
        questions = { '1' => { txt: 'question text', iscorrect: '1' }, '2' => { txt: '', iscorrect: '1' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        expect(quiz_question.isvalid(questions)).to eq('Please make sure every question has text for all options')
      end
    end
  end
  describe '#isvalid' do
    context 'when no choices are correct' do
      it 'returns "Please select a correct answer for all questions"' do
        questions = { '1' => { txt: 'question text', iscorrect: '0' }, '2' => { txt: 'question text', iscorrect: '0' }, '3' => { txt: 'question text', iscorrect: '0' }, '4' => { txt: 'question text', iscorrect: '0' } }
        expect(quiz_question.isvalid(questions)).to eq('Please select a correct answer for all questions')
      end
    end
  end
end
