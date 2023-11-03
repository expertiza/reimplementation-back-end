require 'rails_helper'
include ActionView::Helpers::SanitizeHelper

describe TextArea do
  let(:text_area) { TextArea.create(id: 1, question_type: 'TextArea', seq: 1.0, txt: 'test txt', weight: 5) }
  let(:answer) { Answer.new(answer: 1, comments: 'test answer') }

  let(:completed_question_html) do
    text_area.view_completed_question(3, answer)
  end

  let(:completed_html) do
    text_area.complete(3, nil)
  end

  it 'returns the completed question HTML' do
    expected_html = '<b>3. test txt</b><BR/> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;test answer<BR/><BR/>'
    expect(completed_question_html.gsub(/\s+/, ' ').strip).to eq(expected_html.gsub(/\s+/, ' ').strip)
  end

  it 'returns the completed HTML' do
    expected_html = '<p><label for="responses_3">test txt</label></p> <input id="responses_3_score" name="responses[3][score]" type="hidden" value=""> <p><textarea cols="70" rows="1" id="responses_3_comments" name="responses[3][comment]" class="tinymce"></textarea></p>'
    expect(completed_html.strip.gsub(/\s+/, ' ')).to eq(expected_html.strip.gsub(/\s+/, ' '))
  end
end
