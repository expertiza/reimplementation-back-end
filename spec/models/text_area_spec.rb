require 'rails_helper'

describe TextArea do

  let(:textArea) { TextArea.new }

  describe '#view_completed_question' do
    it 'returns the html' do
      html = textArea.view_completed_question(3, "test txt")
      expect(html).to eq('<b>3.to_s.txt</b><BR/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + answer.comments.gsub('^p', '').gsub(/\n/,'<BR/>') + '<BR/><BR/>')
    end
  end

  describe '#complete' do
    it 'returns the html' do
      html = textArea.complete(3, nil)
      expect(html).to eq('<p><label for="responses_3.to_s"> test txt </label></p><input id="responses_3.to_s_score" name="responses[3.to_s][score]" type="hidden" value=""><p><textarea cols=" 70" rows="1" id="responses_3.to_s_comments" name="responses[3.to_s][comment]" class="tinymce"></textarea></p>')
    end

  end
end