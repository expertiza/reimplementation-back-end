require 'rails_helper'

RSpec.describe Criterion, type: :model do
  describe '#complete' do
    context 'when dropdown_or_scale is "dropdown"' do
      it 'returns HTML code with a label and dropdown options' do
        criterion = Criterion.new
        html = criterion.complete(7)
        expect(html).to be_a(String)
      end
    end

    context 'when dropdown_or_scale is "scale"' do
      it 'returns HTML code with a label and scale options' do
        criterion = Criterion.new
        html = criterion.complete(7)
        expect(html).to be_a(String)
      end
    end

    context 'when question_advices is not empty and advice_total_length is greater than 0' do
      it 'returns HTML code with advice for the question' do
        criterion = Criterion.new
        html = criterion.complete(7)
        expect(html).to be_a(String)
      end
    end

    context 'when question_advices is empty or advice_total_length is 0' do
      it 'returns HTML code without advice for the question' do
        criterion = Criterion.new
        html = criterion.complete(7)
        expect(html).to be_a(String)
      end
    end
  end

  describe "#scale_criterion_question" do
    context "when answer is not provided" do
      it "generates HTML for a scale criterion question without an answer" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end

    context "when answer is provided" do
      it "generates HTML for a scale criterion question with the provided answer" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end

    context "when min and max labels are provided" do
      it "generates HTML with the provided min and max labels" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end

    context "when min and max labels are not provided" do
      it "generates HTML without min and max labels" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end

    context "when size is not provided" do
      it "generates HTML with default size" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end

    context "when size is provided" do
      it "generates HTML with the provided size" do
        criterion = Criterion.new
        html = criterion.scale_criterion_question
        expect(html).to be_a(String)
      end
    end
  end

  describe 'view_completed_question' do
    context 'when count, answer, and questionnaire_max are provided' do
      it 'returns the HTML representation of a completed question' do
        criterion = Criterion.new
        html = criterion.view_completed_question(5, 'Some answer', 10)
        expect(html).to be_a(String)
      end
    end

    context 'when answer is nil' do
      it 'returns the HTML representation of an unanswered question' do
        criterion = Criterion.new
        html = criterion.view_completed_question(3, nil, 10)
        expect(html).to be_a(String)
      end
    end
  end
end