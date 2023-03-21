require 'rails_helper'

describe TextResponse do
  let(:questionnaire) { Questionnaire.new min_question_score: 0, max_question_score: 5 }
  let(:textResponse) { TextResponse.new }

  describe '#edit' do
    it 'returns the html' do
      html = textResponse.edit(3)
      expect(html).to eq('<tr><td align="center"><a rel="nofollow" data-method="delete" href="/questions/11">Remove</a></td><td><input size="6" value="1.0" name="question[11][seq]" id="question_11_seq" type="text"></td><td><textarea cols="50" rows="1" name="question[11][txt]" id="question_11_txt" placeholder="Edit question content here">txt</textarea></td><td><input size="10" disabled="disabled" value="TextResponse" name="question[11][type]" id="question_11_type" type="text"></td><td><!--placeholder (TextResponse does not need weight)--></td><td>text area size <input size="6" value="10" name="question[11][size]" id="question_11_size" type="text"></td></tr>')
    end
  end

  describe '#view_question_text' do
    it 'returns the html' do
      html = textResponse.edit
      expect(html).to eq('<TR><TD align="left">Test txt</TD><TD align="left">TextResponse</TD><TD align="center">1.0</TD><TD align="center">&mdash;</TD></TR>')
    end
  end

end