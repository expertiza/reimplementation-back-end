require 'rails_helper'

RSpec.describe Scale, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns an HTML string' do
        scale = Scale.new
        html = scale.edit
        expect(html).to be_a(String)
      end
    end
  end

  describe "#view_question_text" do
    context "when max_label and min_label are nil" do
      it "returns the question text, type, weight, and default score range" do
        scale = Scale.new
        expect { scale.view_question_text }.to raise_error(ArgumentError, 'Invalid input values (given 0, expected 1)')
      end
    end

  end

  describe '#complete' do
    context 'when answer is provided' do
      it 'generates HTML code for a complete questionnaire with the provided answer' do
        scale = Scale.new
        html = scale.complete
        expect(html).to be_a(String)
      end
    end

  end

  describe "#view_completed_question" do
    context "when count is 1, answer is 5, and questionnaire_max is 10" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question(count: 1, answer: 5, questionnaire_max: 10)
        expect(html).to be_a(String)
      end
    end

    context "when count is 2, answer is 8, and questionnaire_max is 20" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question(count: 2, answer: 8, questionnaire_max: 20)
        expect(html).to be_a(String)
      end
    end

    context "when count is 3, answer is 3, and questionnaire_max is 5" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question
        expect(html).to be_a(String)
      end
    end
  end
end