require 'rails_helper'

describe TextResponse do
  let!(:text_response) { TextResponse.create(id: 1, txt: 'Text Response', size: 35) }

  describe '#edit' do
    it 'returns the html' do
      html = text_response.edit(3)
      expect(html).to eq('<tr><td align="center"><a rel="nofollow" data-method="delete" href="/questions/1">Remove</a></td><td><input size="6" value="" name="question[1][seq]" id="question_1_seq" type="text"></td><td><textarea cols="50" rows="1" name="question[1][txt]" id="question_1_txt" placeholder="Edit question content here">Text Response</textarea></td><td><input size="10" disabled="disabled" value="TextResponse" name="question[1][type]" id="question_1_type" type="text"></td><td><!--placeholder (TextResponse does not need weight)--></td><td>text area size <input size="6" value="35" name="question[1][size]" id="question_1_size" type="text"></td></tr>')
    end
  end

  describe '#view_question_text' do
    it 'returns the html' do
      html = text_response.view_question_text
      expect(html).to eq('<TR><TD align="left"> Text Response </TD><TD align="left">TextResponse</TD><td align="center"></TD><TD align="center">&mdash;</TD></TR>')
    end
  end

end