require 'rails_helper'

RSpec.describe Criterion, type: :model do
  describe '#complete' do
    context 'when dropdown_or_scale is "dropdown"' do
      it 'returns JSON code with a label and dropdown options' do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'dropdown', weight: 2, alternatives: 'Option1|Option2|Option3')

        json_result = criterion.complete(7)

        expected_result = {
          question_type: 'dropdown',
          label: 'Criterion Question',
          options: ['Option1', 'Option2', 'Option3'],
          advice: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when dropdown_or_scale is "scale"' do
      it 'returns JSON code with a label and scale options' do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely')

        json_result = criterion.complete(7)

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          advice: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when question_advices is not empty and advice_total_length is greater than 0' do
      it 'returns JSON code with advice for the question' do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', question_advices: [{ txt: 'Advice1' }, { txt: 'Advice2' }])

        json_result = criterion.complete(7)

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          advice: ['Advice1', 'Advice2']
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when question_advices is empty or advice_total_length is 0' do
      it 'returns JSON code without advice for the question' do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', question_advices: [])

        json_result = criterion.complete(7)

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          advice: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end
  end

  describe "#scale_criterion_question" do
    context "when answer is not provided" do
      it "generates JSON for a scale criterion question without an answer" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely')

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          answer: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when answer is provided" do
      it "generates JSON for a scale criterion question with the provided answer" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', answer: 5)

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          answer: 5
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when min and max labels are provided" do
      it "generates JSON with the provided min and max labels" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', answer: 5)

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          answer: 5
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when min and max labels are not provided" do
      it "generates JSON without min and max labels" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, answer: 5)

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: nil,
          answer: 5
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when size is not provided" do
      it "generates JSON with default size" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', answer: 5)

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          answer: 5,
          size: 'default'
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when size is provided" do
      it "generates JSON with the provided size" do
        criterion = Criterion.new(txt: 'Criterion Question', type: 'scale', weight: 2, min_label: 'Not at all', max_label: 'Completely', answer: 5, size: 'small')

        json_result = criterion.scale_criterion_question

        expected_result = {
          question_type: 'scale',
          label: 'Criterion Question',
          options: ['Not at all', 'Completely'],
          answer: 5,
          size: 'small'
        }
        expect(json_result).to eq(expected_result)
      end
    end
  end

  describe 'view_completed_question' do
    context 'when count, answer, and questionnaire_max are provided' do
      it 'returns the JSON representation of a completed question' do
        criterion = Criterion.new
        json_result = criterion.view_completed_question(5, 'Some answer', 10)

        expected_result = {
          count: 5,
          answer: 'Some answer',
          questionnaire_max: 10
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when answer is nil' do
      it 'returns the JSON representation of an unanswered question' do
        criterion = Criterion.new
        json_result = criterion.view_completed_question(3, nil, 10)

        expected_result = {
          count: 3,
          answer: nil,
          questionnaire_max: 10
        }
        expect(json_result).to eq(expected_result)
      end
    end
  end
end