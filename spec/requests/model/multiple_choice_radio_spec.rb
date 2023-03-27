describe MultipleChoiceRadio do
    let(:quiz_question) { MultipleChoiceRadio.new }
    let(:quiz_question_choice1) { QuizQuestionChoice.new }
    let(:quiz_question_choice2) { QuizQuestionChoice.new }
    let(:quiz_question_choice3) { QuizQuestionChoice.new }
    let(:quiz_question_choice4) { QuizQuestionChoice.new }

    # create MultipleChoiceRadio object with associated QuizQuestionChoices used in tests within this file
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

      quiz_question.quiz_question_choices << quiz_question_choice1
      quiz_question.quiz_question_choices << quiz_question_choice2
      quiz_question.quiz_question_choices << quiz_question_choice3
      quiz_question.quiz_question_choices << quiz_question_choice4

    end

    describe '#edit' do
        it 'returns the correct HTML question when editing a multiple choice radio question' do
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

            [0, 1, 2, 3].each do |i|
                expected_html += '<tr><td>'
            
                expected_html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceRadio][correctindex]" '
                expected_html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceRadio_correctindex_' + (i + 1).to_s + '" value="' + (i + 1).to_s + '" '
                expected_html += 'checked="checked" ' if quiz_question.quiz_question_choices[i].iscorrect
                expected_html += '/>'
            
                expected_html += '<input type="text" name="quiz_question_choices[' + id.to_s + '][MultipleChoiceRadio][' + (i + 1).to_s + '][txt]" '
                expected_html += 'id="quiz_question_choices_' + id.to_s + '_MultipleChoiceRadio_' + (i + 1).to_s + '_txt" '
                expected_html += 'value="' + quiz_question.quiz_question_choices[i].txt + '" size="40" />'
            
                expected_html += '</td></tr>'
            end

            expect(quiz_question.edit()).to eq(expected_html)
        end
    end
end