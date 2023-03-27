describe TrueFalse do
    let(:quiz_question) { TrueFalse.new }
    let(:quiz_question_choice1) { QuizQuestionChoice.new }
    let(:quiz_question_choice2) { QuizQuestionChoice.new }
    let(:quiz_question_choice3) { QuizQuestionChoice.new }
    let(:quiz_question_choice4) { QuizQuestionChoice.new }

    # create TrueFalse object with associated QuizQuestionChoices used in tests within this file
    before(:each) do
      quiz_question.quiz_question_choices = [quiz_question_choice1, quiz_question_choice2]
      quiz_question.txt = 'Question Text'
      allow(quiz_question).to receive(:type).and_return('TrueFalse')
      allow(quiz_question).to receive(:id).and_return(99)
      allow(quiz_question).to receive(:weight).and_return(5)
      allow(quiz_question_choice1).to receive(:txt).and_return('True')
      allow(quiz_question_choice1).to receive(:question_id).and_return(99)
      allow(quiz_question_choice1).to receive(:iscorrect?).and_return(true)
      allow(quiz_question_choice2).to receive(:txt).and_return('False')
      allow(quiz_question_choice2).to receive(:question_id).and_return(99)
      allow(quiz_question_choice2).to receive(:iscorrect?).and_return(false)

      quiz_question.quiz_question_choices << quiz_question_choice1
      quiz_question.quiz_question_choices << quiz_question_choice2
    end

    describe '#edit' do
        it 'returns the correct HTML question when editing a true/false question' do
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

            expected_html += '<tr><td>'
            expected_html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][TrueFalse][1][iscorrect]" '
            expected_html += 'id="quiz_question_choices_' + id.to_s + '_TrueFalse_1_iscorrect_True" value="True" '
            expected_html += 'checked="checked" ' if quiz_question.quiz_question_choices[0].iscorrect
            expected_html += '/>True'
            expected_html += '</td></tr>'

            expected_html += '<tr><td>'
            expected_html += '<input type="radio" name="quiz_question_choices[' + id.to_s + '][TrueFalse][1][iscorrect]" '
            expected_html += 'id="quiz_question_choices_' + id.to_s + '_TrueFalse_1_iscorrect_True" value="False" '
            expected_html += 'checked="checked" ' if quiz_question.quiz_question_choices[1].iscorrect
            expected_html += '/>False'
            expected_html += '</td></tr>'

            expect(quiz_question.edit()).to eq(expected_html)
        end
    end

    describe '#complete' do
        it 'returns the correct HTML question when viewing true/false question to complete' do
            id = quiz_question.id
            txt = quiz_question.txt

            expected_html = '<label for="' + id.to_s + '">' + txt + '</label><br>'
            (0..1).each do |i|
                expected_html += '<input name = ' + "\"#{id}\" "
                expected_html += 'id = ' + "\"#{id}" + '_' + "#{i + 1}\" "
                expected_html += 'value = ' + "\"#{quiz_question.quiz_question_choices[i].txt}\" "
                expected_html += 'type="radio"/>'
                expected_html += if i == 0
                                    'True'
                                else
                                    'False'
                                end
                expected_html += '</br>'
            end

            expect(quiz_question.complete()).to eq(expected_html)
        end
    end

    describe '#view_completed_question' do
        it 'returns the correct HTML question when viewing correctly completed true/false question' do
            id = quiz_question.id
            txt = quiz_question.txt

            user_answer = double('user_answer')
            allow(user_answer).to receive_message_chain(:first, :comments).and_return('True')
            allow(user_answer).to receive_message_chain(:first, :answer).and_return(1)

            expected_html = "Correct Answer is: <b>False</b><br/>Your answer is: <b>True<img src=\"/assets/Check-icon.png\"/></b><br><br><hr>"

            expect(quiz_question.view_completed_question(user_answer)).to eq(expected_html)
        end

        it 'returns the correct HTML question when viewing incorrectly completed true/false question' do
            id = quiz_question.id
            txt = quiz_question.txt

            user_answer = double('user_answer')
            allow(user_answer).to receive_message_chain(:first, :comments).and_return('False')
            allow(user_answer).to receive_message_chain(:first, :answer).and_return(0)

            expected_html = "Correct Answer is: <b>False</b><br/>Your answer is: <b>False<img src=\"/assets/delete_icon.png\"/></b><br><br><hr>"

            expect(quiz_question.view_completed_question(user_answer)).to eq(expected_html)
        end
    end

end