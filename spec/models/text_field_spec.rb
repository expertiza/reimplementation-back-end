require 'rails_helper'

describe TextField do
  let!(:text_field) { TextField.create(id: 1, txt: 'Field Text', question_type: 'TextField', size: 35) }
  let!(:answer) { Answer.new(answer: 1, comments: 'test answer', question_id: 7) }

  describe '#view_completed_question' do
    it 'returns the html for TextField type' do
      text_field.question_type = 'TextField' # Set the question_type
      text_field.break_before = true # Set break_before to true

      html = text_field.view_completed_question(3, answer)
      results_string = '<b>3. Field Text</b>&nbsp;&nbsp;&nbsp;&nbsp;test answer'
      results_string += '<br><br>' if Question.exists?(answer.question_id + 1) && Question.find(answer.question_id + 1).break_before == true
      expect(html).to eq(results_string)
    end

    it 'returns the html for non-TextField type' do
      text_field.question_type = 'SomeOtherType' # Set the question_type to something other than 'TextField'
      html = text_field.view_completed_question(3, answer)
      expect(html).to eq('Field Texttest answer<br><br>')
    end
  end

  describe '#complete' do
    it 'returns the html' do
      html = text_field.complete(3, nil)
      results_string = '<p style="width: 80%;"><label for="responses_3">Field Text&nbsp;&nbsp;</label>'
      results_string += '<input id="responses_3_score" name="responses[3][score]" type="hidden" value="">'
      results_string += '<input id="responses_3_comments" name="responses[3][comment]" style="width: 40%;" size="35" type="text" value=""><br><br>'
      expect(html).to eq(results_string)
    end
  end

end



