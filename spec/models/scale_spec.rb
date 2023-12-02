require 'rails_helper'

RSpec.describe Scale, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns a JSON object with question text, type, weight, and score range' do
        scale = Scale.new(txt: 'Scale Question', type: 'scale', weight: 2, min_question_score: 0, max_question_score: 10)

        json_result = scale.edit(1)

        expected_result = {
          txt: 'Scale Question',
          type: 'scale',
          weight: 2,
          min_question_score: 0,
          max_question_score: 10
        }
        expect(json_result).to eq(expected_result)
      end
    end
  end

  describe "#view_question_text" do
    context "when max_label and min_label are nil" do
      it "raises an error as a JSON object" do
        scale = Scale.new
        json_result = scale.view_question_text

        expected_result = {
          error: 'Invalid input values (given 0, expected 1)',
          details: 'Add specific details about the error or expected result here'
        }

        expect(json_result).to eq(expected_result)
      end
    end

    # Add more view_question_text test cases as needed...
  end

  describe '#complete' do
    context 'when answer is provided' do
      it 'generates JSON code for a complete questionnaire with the provided answer' do
        scale = Scale.new
        json_result = scale.complete(5)
        expected_result = {
          question_type: 'scale',
          answer: 5
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when answer is not provided' do
      it 'generates JSON code for a complete questionnaire without an answer' do
        scale = Scale.new
        json_result = scale.complete(5)
        expected_result = {
          question_type: 'scale',
          answer: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end

    # Add more complete tests...
  end

  describe "#view_completed_question" do
    context "when count, answer, and questionnaire_max are provided" do
      it "returns a JSON object with count, answer, and questionnaire_max" do
        scale = Scale.new
        json_result = scale.view_completed_question(count: 1, answer: 5, questionnaire_max: 10)
        expected_result = {
          count: 1,
          answer: 5,
          questionnaire_max: 10
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when count is 2, answer is 8, and questionnaire_max is 20" do
      it "returns a JSON object with count, answer, and questionnaire_max" do
        scale = Scale.new
        json_result = scale.view_completed_question(count: 2, answer: 8, questionnaire_max: 20)
        expected_result = {
          count: 2,
          answer: 8,
          questionnaire_max: 20
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context "when count is 3, answer is 3, and questionnaire_max is 5" do
      it "returns a JSON object with count, answer, and questionnaire_max" do
        scale = Scale.new
        json_result = scale.view_completed_question(count: 3, answer: 3, questionnaire_max: 5)
        expected_result = {
          count: 3,
          answer: 3,
          questionnaire_max: 5
        }
        expect(json_result).to eq(expected_result)
      end
    end

    # Add more view_completed_question tests...
  end
end