require 'swagger_helper'

describe MultipleChoiceCheckbox do
  let(:multiple_choice_question) { MultipleChoiceCheckbox.new }
  let(:multiple_choice1) { QuizQuestionChoice.new }
  let(:multiple_choice2) { QuizQuestionChoice.new }
  let(:multiple_choice3) { QuizQuestionChoice.new }
  let(:multiple_choice4) { QuizQuestionChoice.new }

  # create MultipleChoiceCheckbox object with associated QuizQuestionChoices used in tests within this file
  before(:each) do
    multiple_choice_question.quiz_question_choices = [multiple_choice1, multiple_choice2, multiple_choice3, multiple_choice4]
    multiple_choice_question.txt = 'Question Text'
    allow(multiple_choice_question).to receive(:type).and_return('MultipleChoiceCheckbox')
    allow(multiple_choice_question).to receive(:id).and_return(99)
    allow(multiple_choice_question).to receive(:weight).and_return(5)
    allow(multiple_choice1).to receive(:txt).and_return('Choice 1')
    allow(multiple_choice1).to receive(:question_id).and_return(99)
    allow(multiple_choice1).to receive(:iscorrect?).and_return(true)
    allow(multiple_choice2).to receive(:txt).and_return('Choice 2')
    allow(multiple_choice2).to receive(:question_id).and_return(99)
    allow(multiple_choice2).to receive(:iscorrect?).and_return(false)
    allow(multiple_choice3).to receive(:txt).and_return('Choice 3')
    allow(multiple_choice3).to receive(:question_id).and_return(99)
    allow(multiple_choice3).to receive(:iscorrect?).and_return(false)
    allow(multiple_choice4).to receive(:txt).and_return('Choice 4')
    allow(multiple_choice4).to receive(:question_id).and_return(99)
    allow(multiple_choice4).to receive(:iscorrect?).and_return(false)

    multiple_choice_question.quiz_question_choices << multiple_choice1
    multiple_choice_question.quiz_question_choices << multiple_choice2
    multiple_choice_question.quiz_question_choices << multiple_choice3
    multiple_choice_question.quiz_question_choices << multiple_choice4
  end

  describe '#complete' do
    it 'returns the correct HTML question when viewing multiple choice checkbox question to complete' do
        id = multiple_choice_question.id
        txt = multiple_choice_question.txt

        expected_html = '<label for="' + id.to_s + '">' + txt + '</label><br>'
        [0, 1, 2, 3].each do |i|
          # txt = quiz_question_choices[i].txt
          expected_html += '<input name = ' + "\"#{id}[]\" "
          expected_html += 'id = ' + "\"#{id}" + '_' + "#{i + 1}\" "
          expected_html += 'value = ' + "\"#{multiple_choice_question.quiz_question_choices[i].txt}\" "
          expected_html += 'type="checkbox"/>'
          expected_html += multiple_choice_question.quiz_question_choices[i].txt.to_s
          expected_html += '</br>'
        end

        expect(multiple_choice_question.complete()).to eq(expected_html)
    end
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

  describe '#edit' do
        it 'returns the correct HTML question when editing a multiple choice checkbox question' do
            id = multiple_choice_question.id
            txt = multiple_choice_question.txt
            weight = multiple_choice_question.weight

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

            [0, 1, 2, 3].each do |i|
              expected_html += '<tr><td>'

              expected_html += '<input type="hidden" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceCheckbox][' + (i + 1).to_s + '][iscorrect]" '
              expected_html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceCheckbox_' + (i + 1).to_s + '_iscorrect" value="0" />'
        
              expected_html += '<input type="checkbox" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceCheckbox][' + (i + 1).to_s + '][iscorrect]" '
              expected_html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceCheckbox_' + (i + 1).to_s + '_iscorrect" value="1" '
              expected_html += 'checked="checked" ' if multiple_choice_question.quiz_question_choices[i].iscorrect
              expected_html += '/>'
        
              expected_html += '<input type="text" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceCheckbox][' + (i + 1).to_s + '][txt]" '
              expected_html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceCheckbox_' + (i + 1).to_s + '_txt" '
              expected_html += 'value="' + multiple_choice_question.quiz_question_choices[i].txt + '" size="40" />'
        
              expected_html += '</td></tr>'
            end

            expect(multiple_choice_question.edit()).to eq(expected_html)
        end
    end
end
