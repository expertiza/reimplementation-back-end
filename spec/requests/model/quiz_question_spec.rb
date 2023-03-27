require 'swagger_helper'

describe QuizQuestion do
  let(:quiz_question) { QuizQuestion.new }
  let(:quiz_question_choice1) { QuizQuestionChoice.new }
  let(:quiz_question_choice2) { QuizQuestionChoice.new }
  let(:quiz_question_choice3) { QuizQuestionChoice.new }
  let(:quiz_question_choice4) { QuizQuestionChoice.new }

  # create QuizQuestion object with associated QuizQuestionChoices used in tests within this file
  before(:each) do
    quiz_question.quiz_question_choices = [quiz_question_choice1, quiz_question_choice2, quiz_question_choice3, quiz_question_choice4]
    quiz_question.txt = 'Question Text'
    allow(quiz_question).to receive(:type).and_return('MultipleChoiceRadio')
    allow(quiz_question).to receive(:id).and_return(99)
    allow(quiz_question).to receive(:weight).and_return(5)
    allow(quiz_question_choice1).to receive(:txt).and_return('Choice 1')
    allow(quiz_question_choice1).to receive(:question_id).and_return(99)
    allow(quiz_question_choice1).to receive(:iscorrect?).and_return(true)
    allow(quiz_question_choice2).to receive(:txt).and_return('Choice 2')
    allow(quiz_question_choice2).to receive(:question_id).and_return(99)
    allow(quiz_question_choice2).to receive(:iscorrect?).and_return(false)
    allow(quiz_question_choice3).to receive(:txt).and_return('Choice 3')
    allow(quiz_question_choice3).to receive(:question_id).and_return(99)
    allow(quiz_question_choice3).to receive(:iscorrect?).and_return(false)
    allow(quiz_question_choice4).to receive(:txt).and_return('Choice 4')
    allow(quiz_question_choice4).to receive(:question_id).and_return(99)
    allow(quiz_question_choice4).to receive(:iscorrect?).and_return(false)
  end
 
  describe '#view_question_text' do
    it 'returns the text of the questions' do
      weight = quiz_question.weight
      expect(quiz_question.view_question_text).to eq('<b>Question Text</b><br />Question Type: MultipleChoiceRadio<br />Question Weight: ' + weight.to_s + '<br />  - <b>Choice 1</b><br />   - Choice 2<br />   - Choice 3<br />   - Choice 4<br /> <br />')
    end
  end
  describe '#get_formatted_question_type' do
    it 'returns the type' do
      expect(quiz_question.get_formatted_question_type).to eq('Multiple Choice - Radio')
    end
  end

  describe "#complete" do
    before do
      id = quiz_question.id
      expected_html = "<label for=\"" + id.to_s + "\">Question Text</label><br><input name = \"" + id.to_s + "\" id = \"" + id.to_s + "_1\" value = \"Choice 1\" type=\"radio\"/>Choice 1</br><input name = \"" + id.to_s + "\" id = \"" + id.to_s + "_2\" value = \"Choice 2\" type=\"radio\"/>Choice 2</br><input name = \"" + id.to_s + "\" id = \"" + id.to_s + "_3\" value = \"Choice 3\" type=\"radio\"/>Choice 3</br><input name = \"" + id.to_s + "\" id = \"" + id.to_s + "_4\" value = \"Choice 4\" type=\"radio\"/>Choice 4</br>"
      expect(quiz_question.complete).to eq(expected_html)
    end
    it "returns the completed HTML for the quiz question" do
      # The before block already tests the functionality, so this test can be empty
    end
  end
  
   describe '#view_completed_question' do
    it 'returns the correct HTML for a completed question' do
      quiz_question = QuizQuestion.new(txt: 'which is the latest Iphone?')
      quiz_question_choice_1 = QuizQuestionChoice.new(txt: 'Iphone14', iscorrect: true)
      quiz_question_choice_2 = QuizQuestionChoice.new(txt: 'Iphone13', iscorrect: false)
      quiz_question_choice_3 = QuizQuestionChoice.new(txt: 'Iphone12', iscorrect: false)
      quiz_question.quiz_question_choices << quiz_question_choice_1
      quiz_question.quiz_question_choices << quiz_question_choice_2
      quiz_question.quiz_question_choices << quiz_question_choice_3
      user_answer = double('user_answer')
      allow(user_answer).to receive_message_chain(:first, :comments).and_return('Iphone14')
      allow(user_answer).to receive_message_chain(:first, :answer).and_return(1)

      expected_html = '<b>Iphone14</b> -- Correct <br>Iphone13<br>Iphone12<br><br>Your answer is: <b>Iphone14</b><img src="/assets/Check-icon.png"/></b><br><br><hr>'

      expect(quiz_question.view_completed_question(user_answer)).to eq(expected_html)
    end
  end
    
  describe '#edit' do
    it 'returns the correct HTML question prefix when editing a question' do
      id = quiz_question.id
      txt = quiz_question.txt
      weight = quiz_question.weight

      expected_html = '<tr><td>'
      expected_html += '<textarea cols="100" name="question[' + id.to_s + '][txt]" '
      expected_html += 'id="question_' + id.to_s + '_txt">' + txt + '</textarea>'
      expected_html += '</td></tr>'
  
      expected_html += '<tr><td>'
      expected_html += 'Question Weight: '
      expected_html += '<input type="number" name="question_weights[' + id.to_s + '][txt]" '
      expected_html += 'id="question_wt_' + id.to_s + '_txt" '
      expected_html += 'value="' + weight.to_s + '" min="0" />'
      expected_html += '</td></tr>'

      expect(quiz_question.edit()).to eq(expected_html)
    end
  end


  describe '#isvalid' do
    context 'when the question and its choices have valid text' do
      it 'returns "valid"' do
        questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: false } }
        expect(quiz_question.isvalid(questions)).to eq('valid')
      end
    end
  end
  describe '#isvaid' do
    let(:no_text_question) {QuizQuestion.new}
    context 'when the question itself does not have txt' do
      it 'returns "Please make sure all questions have text"' do
        allow(no_text_question).to receive(:txt).and_return('')
        questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: false } }
        expect(no_text_question.isvalid(questions)).to eq('Please make sure all questions have text')
      end
    end
  end
  describe '#isvalid' do
    context 'when a choice does not have text' do
      it 'returns "Please make sure every question has text for all options"' do
        questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: '', iscorrect: true }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: false } }
        expect(quiz_question.isvalid(questions)).to eq('Please make sure every question has text for all options')
      end
    end
  end
  describe '#isvalid' do
    context 'when no choices are correct' do
      it 'returns "Please select a correct answer for all questions"' do
        questions = { '1' => { txt: 'question text', iscorrect: false }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: false } }
        expect(quiz_question.isvalid(questions)).to eq('Please select a correct answer for all questions')
      end
    end
  end
  describe '#isvalid' do
    context 'when there are more than one correct choices' do
      it 'returns "Please select only one correct answer for all questions"' do
        questions = questions = { '1' => { txt: 'question text', iscorrect: true }, '2' => { txt: 'question text', iscorrect: false }, '3' => { txt: 'question text', iscorrect: false }, '4' => { txt: 'question text', iscorrect: true } }
        expect(quiz_question.isvalid(questions)).to eq('Please select only one correct answer for all questions')
      end
    end
  end
end
