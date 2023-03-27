require 'rails_helper'

describe TextField do

  let!(:text_field) { TextField.create(id: 1, txt: 'Field Text', type: 'TextField', size: 35) }
  let!(:answer) { Answer.new answer: 1, comments: 'test answer', question_id: 7 }

  describe '#view_completed_question' do
    it 'returns the html for TextField type' do
      html = text_field.view_completed_question(3, answer)
      results_string = '<b>3. Field Text</b>&nbsp;&nbsp;&nbsp;&nbsp;test answer'
      results_string += '<BR/><BR/>' if Question.exists?(answer.question_id + 1) && Question.find(answer.question_id + 1).break_before == true
      expect(html).to eq(results_string)
    end

    it 'returns the html for non TextField type' do
      html = text_field.view_completed_question(3, answer)
      expect(html).to eq('<b>3. Field Text</b>&nbsp;&nbsp;&nbsp;&nbsp;test answer')
    end
  end

  describe '#complete' do
    it 'returns the html' do
      html = text_field.complete(3, nil)
      results_string = '<p style="width: 80%;"><label for="responses_3" >Field Text&nbsp;&nbsp;</label><input id="responses_3_score" name="responses[3][score]" type="hidden" value="" "><input id="responses_3_comments" label=Field Text name="responses[3][comment]" style="width: 40%;" size=35 type="text"">'
      expect(html).to eq(results_string)
    end
  end
end