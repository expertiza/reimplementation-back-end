require 'rails_helper'

describe MultipleChoiceRadio do

  let!(:multiple_choice_radio) { MultipleChoiceRadio.create(id: 1, type: 'MultipleChoiceRadio', seq: 4.0, txt: 'Test text', weight: 13) }
  let!(:assignment) { Assignment.create(id: 1, name: 'assignment') }
  let!(:questionnaire) { Questionnaire.create(id: 2, name: 'Questions', min_question_score: 0, max_question_score: 5) }

  describe '#is_valid' do
    context 'when the question itself does not have txt' do
      it 'returns "Please make sure all questions have text"' do
        allow(multiple_choice_radio).to receive(:txt).and_return('')
        questions = { '1' => { txt: 'question text', correct: '1' }, '2' => { txt: 'question text', correct: '1' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_radio.is_valid(questions)).to eq('Please make sure all questions have text')
      end
    end
    context 'when a choice does not have txt' do
      it 'returns "Please make sure every question has text for all options"' do
        questions = { '1' => { txt: '', correct: '1' }, '2' => { txt: '', correct: '1' }, '3' => { txt: '', correct: '0' }, '4' => { txt: '', correct: '0' } }
        expect(multiple_choice_radio.is_valid(questions)).to eq('Please select a correct answer for all questions')
      end
    end
    context 'when no choices are correct' do
      it 'returns "Please select a correct answer for all questions"' do
        questions = { '1' => { txt: 'question text', correct: '0' }, '2' => { txt: 'question text', correct: '0' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_radio.is_valid(questions)).to eq('Please select a correct answer for all questions')
      end
    end
  end

  describe '#formatted_question_type' do
    it 'returns "Multiple Choice - Radio"' do
      expect(multiple_choice_radio.formatted_question_type).to eq('Multiple Choice - Radio')
    end
  end
  describe '#export_fields' do
    it 'returns the column headers' do
      expect(Question.export_fields([])).to eq(['Seq', 'Question', 'Type', 'Weight', 'text area size', 'max_label', 'min_label'])
    end
  end
  describe '#import' do
    context 'when the row length is not 5' do
      it 'throws an error' do
        expect { Question.import(%w[header1 header2 header3], [], [], nil) }.to raise_error(ArgumentError)
      end
    end
    context 'when there is no questionnaire' do
      it 'throws an error' do
        allow(Questionnaire).to receive(:find_by).with(id: 1).and_return(nil)
        expect { Question.import(%w[header1 header2 header3 header4 header5], [], [], 1) }.to raise_error(ArgumentError)
      end
    end
  end
  describe '#export' do
    it 'writes to a csv file' do
      csv = []
      allow(Questionnaire).to receive(:find).with(1).and_return(questionnaire)
      allow(questionnaire).to receive(:questions).and_return([multiple_choice_radio])
      expect(Question.export(csv, 1, nil)).to eq([multiple_choice_radio])
    end
  end
end