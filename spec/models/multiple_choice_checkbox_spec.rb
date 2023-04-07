require 'rails_helper'

describe MultipleChoiceCheckbox do
#   let(:multiple_choice_checkbox) { build(:multiple_choice_checkbox, id: 1) }
#   let(:questionnaire1) { build(:questionnaire, id: 1, type: 'ReviewQuestionnaire') }
#   let(:questionnaire2) { build(:questionnaire, id: 2, type: 'MetareviewQuestionnaire') }
#   let(:team) { build(:assignment_team, id: 1, name: 'no team') }
#   let(:participant) { build(:participant, id: 1) }
#   let(:assignment) { build(:assignment, id: 1, name: 'no assignment', participants: [participant], teams: [team]) }
#   let(:scored_question) { build(:scored_question, id: 1) }
#   let(:question) { build(:question) }

  let!(:multiple_choice_checkbox) { MultipleChoiceCheckbox.create(id: 1, type: 'MultipleChoiceCheckbox', seq: 4.0, txt: 'Test text', weight: 13) }
  let!(:assignment) { Assignment.create(id: 1, name: 'assignment') }
  let!(:questionnaire) { Questionnaire.create(id: 2, name: 'Questions', min_question_score: 0, max_question_score: 5) }

  describe '#is_valid' do
    context 'when the question itself does not have txt' do
      it 'returns "Please make sure all questions have text"' do
        allow(multiple_choice_checkbox).to receive(:txt).and_return('')
        questions = { '1' => { txt: 'question text', correct: '1' }, '2' => { txt: 'question text', correct: '1' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_checkbox.is_valid(questions)).to eq('Please make sure all questions have text.')
      end
    end
    context 'when a choice does not have txt' do
      it 'returns "Please make sure every question has text for all options"' do
        questions = { '1' => { txt: '', correct: '1' }, '2' => { txt: '', correct: '1' }, '3' => { txt: '', correct: '0' }, '4' => { txt: '', correct: '0' } }
        expect(multiple_choice_checkbox.is_valid(questions)).to eq('Please select a correct answer for all questions.')
      end
    end
    context 'when no choices are correct' do
      it 'returns "Please select a correct answer for all questions"' do
        questions = { '1' => { txt: 'question text', correct: '0' }, '2' => { txt: 'question text', correct: '0' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_checkbox.is_valid(questions)).to eq('Please select a correct answer for all questions.')
      end
    end
    context 'when only 1 choices are correct' do
      it 'returns "A multiple-choice checkbox question should have more than one correct answer."' do
        questions = { '1' => { txt: 'question text', correct: '1' }, '2' => { txt: 'question text', correct: '0' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_checkbox.is_valid(questions)).to eq('A multiple-choice checkbox question should have more than one correct answer.')
      end
    end
    context 'when 2 choices are correct' do
      it 'returns "valid"' do
        questions = { '1' => { txt: 'question text', correct: '1' }, '2' => { txt: 'question text', correct: '1' }, '3' => { txt: 'question text', correct: '0' }, '4' => { txt: 'question text', correct: '0' } }
        expect(multiple_choice_checkbox.is_valid(questions)).to eq('Valid')
      end
    end
  end
  describe '#formatted_question_type' do
    it 'returns "Multiple Choice - Checked"' do
      expect(multiple_choice_checkbox.formatted_question_type).to eq('Multiple Choice - Checked')
    end
  end
  describe '#export_fields' do
    it 'returns the column headers' do
      expect(Question.export_fields([])).to eq(['Seq', 'Question', 'Type', 'Weight', 'text area size', 'max_label', 'min_label'])
    end
  end
#   describe '#questions_with_comments' do
#     context 'when the assignment has no questionnaires associated' do
#       it 'returns an empty array' do
#         allow(Assignment).to receive(:find).with(1).and_return(assignment)
#         allow(assignment).to receive(:questionnaires).and_return([])
#         expect(Question.questions_with_comment(assignment.id)).to eq([])
#       end
#     end
#     context 'when the assignment has two questionnaires associated, metareview and review, with one scored question' do
#       it 'returns an array of the id of the scored question' do
#         allow(Assignment).to receive(:find).with(1).and_return(assignment)
#         allow(assignment).to receive(:questionnaires).and_return([questionnaire1, questionnaire2])
#         allow(questionnaire1).to receive(:questions).and_return([scored_question])
#         expect(Question.questions_with_comments(assignment.id)).to eq([1])
#       end
#     end
#   end
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
      allow(questionnaire).to receive(:questions).and_return([multiple_choice_checkbox])
      expect(Question.export(csv, 1, nil)).to eq([multiple_choice_checkbox])
    end
  end
end
