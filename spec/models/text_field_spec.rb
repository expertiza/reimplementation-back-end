require 'rails_helper'

describe TextField do

  let(:textField) { TextField.new }

  describe '#view_completed_question' do
    it 'returns the html for TextField type' do
      html = textField.view_completed_question(3, "test txt")
      resultsString = '<b>count.to_s.txt</b>&nbsp;&nbsp;&nbsp;&nbsp;answer.comments.to_s'
      resultsString += '<BR/><BR/>' if Question.exists?(answer.question_id + 1) && Question.find(answer.question_id + 1).break_before == true
      expect(html).to eq(resultsString)
    end

    it 'returns the html for non TextField type' do
    end
      html = textField.view_completed_question(3, "test txt")
      expect(html).to eq('txt answer.comments <BR/><BR/>')
    end
  end

  describe '#complete' do
    it 'returns the html' do
      html = textField.view_completed_question(3, nil)
      resultsString = '<p style="width: 80%;"><label for="responses_3.to_s" > txt &nbsp;&nbsp;</label><input id="responses_3.to_s_score" name="responses[3.to_s][score]" type="hidden" value=" "><input id="responses_3.to_s_comments" label="txt" name="responses[3.to_s][comment]" style="width: 40%;" size=“size.to_s” type="text" value=" ">'
      resultsString += '<BR/><BR/>' + if (type == 'TextField') && (break_before == false)
      expect(html).to eq(resultsString)
    end

  end
end