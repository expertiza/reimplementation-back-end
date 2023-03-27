require 'rails_helper'

describe TextArea do

  let!(:text_area) { TextArea.create(id: 1, type: 'TextArea', seq: 1.0, txt: 'test txt', weight: 5) }
  let!(:answer) { Answer.new answer: 1, comments: 'test answer' }

  describe '#view_completed_question' do
    it 'returns the html' do
      html = text_area.view_completed_question(3, answer)
      expect(html).to eq('<b>3. test txt</b><BR/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + answer.comments.gsub('^p', '').gsub(/\n/,'<BR/>') + '<BR/><BR/>')
    end
  end

  describe '#complete' do
    it 'returns the html' do
      html = text_area.complete(3, nil)
      expect(html).to eq('<p><label for="responses_3">test txt</label></p><input id="responses_3_score" name="responses[3][score]" type="hidden" value=""><p><textarea cols="70" rows="1" id="responses_3_comments" name="responses[3][comment]" class="tinymce"></textarea></p>')
    end

  end
end