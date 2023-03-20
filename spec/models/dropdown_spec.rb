require 'rails_helper'

describe Dropdown do
#   let(:dropdown) { build(:dropdown, id: 1) }
#   let(:questionnaire) { create(:questionnaire, id: 1) }
#   let(:question1) { create(:question, questionnaire: questionnaire, weight: 1, id: 1, type: 'Criterion') }
  let!(:dropdown) { Dropdown.create(id: 4, type: 'Dropdown', seq: 4.0, txt: 'Test text', weight: 13) }
#   let(:response_map) { create(:review_response_map, id: 1, reviewed_object_id: 1) }
#   let!(:response_record) { create(:response, id: 1, response_map: response_map) }
#   let!(:answer) { create(:answer, question: question1, comments: 'Alternative 1', response_id: 1) }
  let!(:answer) { Answer.create(id: 1, question_id: 4, questionnaire_type_id: 1, answer: 1, comments: "Test comment") }
  describe '#view_question_text' do
    it 'returns the html' do
      html = dropdown.view_question_text
      expect(html).to eq('<TR><TD align="left"> Test text </TD><TD align="left">Dropdown</TD><td align="center">13</TD><TD align="center">&mdash;</TD></TR>')
    end
  end
  describe '#view_completed_question' do
    it 'returns the html' do
      html = dropdown.view_completed_question(1, answer)
      expect(html).to eq('<b>1. Test text</b><BR>&nbsp&nbsp&nbsp&nbspTest comment')
    end
  end
  describe '#complete_for_alternatives' do
    it 'returns the html' do
      alternatives = ['Alternative 1', 'Alternative 2', 'Alternative 3']
      html = dropdown.complete_for_alternatives(alternatives, answer)
      expect(html).to eq('<option value="Alternative 1">Alternative 1</option><option value="Alternative 2">Alternative 2</option><option value="Alternative 3">Alternative 3</option>')
    end
  end
  describe '#complete' do
    it 'returns the html' do
      alternatives = ['Alternative 1|Alternative 2|Alternative 3']
      allow(dropdown).to receive(:alternatives).and_return(alternatives)
      allow(dropdown).to receive(:complete_for_alternatives).and_return('')
      html = dropdown.complete(1, answer)
      expect(html).to eq('<p style="width: 80%;"><label for="responses_1"">Test text&nbsp;&nbsp;</label><input id="responses_1_score" name="responses[1][score]" type="hidden" value="" style="min-width: 100px;"><select id="responses_1_comments" label=Test text name="responses[1][comment]"></select></p>')
    end
  end
end
