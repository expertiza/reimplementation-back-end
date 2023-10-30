require 'rails_helper'

RSpec.describe Scale, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns an HTML string' do
        scale = Scale.new
        html = scale.edit(count: 5)
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end
  end

  describe "#view_question_text" do
    context "when max_label and min_label are nil" do
      it "returns the question text, type, weight, and default score range" do
        scale = Scale.new
        html = scale.view_question_text(
          txt: "Question 1",
          type: "Multiple Choice",
          weight: 1,
          min_label: nil,
          max_label: nil
        )
        expect(html).to eq('<TR><TD align="left">Question 1</TD><TD align="left">Multiple Choice</TD><td align="center">1</TD><TD align="center">0 to 10</TD></TR>')
      end
    end

    context "when max_label and min_label are not nil" do
      it "returns the question text, type, weight, and custom score range" do
        scale = Scale.new
        html = scale.view_question_text(
          txt: "Question 2",
          type: "Open-ended",
          weight: 2,
          min_label: "Not Satisfied",
          max_label: "Very Satisfied"
        )
        expect(html).to eq('<TR><TD align="left">Question 2</TD><TD align="left">Open-ended</TD><td align="center">2</TD><TD align="center">(Not Satisfied) 0 to 10 (Very Satisfied)</TD></TR>')
      end
    end
  end

  describe '#complete' do
    context 'when answer is provided' do
      it 'generates HTML code for a complete questionnaire with the provided answer' do
        scale = Scale.new
        html = scale.complete(answer: 7)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context 'when answer is not provided' do
      it 'generates HTML code for a complete questionnaire without any answer' do
        scale = Scale.new
        html = scale.complete(answer: nil)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context 'when min_label is provided' do
      it 'generates HTML code for a complete questionnaire with the provided min_label' do
        scale = Scale.new
        html = scale.complete(answer: 5, min_label: "Low")
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context 'when min_label is not provided' do
      it 'generates HTML code for a complete questionnaire without any min_label' do
        scale = Scale.new
        html = scale.complete(answer: 6, min_label: nil)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context 'when max_label is provided' do
      it 'generates HTML code for a complete questionnaire with the provided max_label' do
        scale = Scale.new
        html = scale.complete(answer: 8, max_label: "High")
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context 'when max_label is not provided' do
      it 'generates HTML code for a complete questionnaire without any max_label' do
        scale = Scale.new
        html = scale.complete(answer: 9, max_label: nil)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end
  end

  describe "#view_completed_question" do
    context "when count is 1, answer is 5, and questionnaire_max is 10" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question(count: 1, answer: 5, questionnaire_max: 10)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context "when count is 2, answer is 8, and questionnaire_max is 20" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question(count: 2, answer: 8, questionnaire_max: 20)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end

    context "when count is 3, answer is 3, and questionnaire_max is 5" do
      it "returns the HTML string with count, answer, and questionnaire_max" do
        scale = Scale.new
        html = scale.view_completed_question(count: 3, answer: 3, questionnaire_max: 5)
        expect(html).to be_a(String)
        # Add more specific expectations for the HTML structure
      end
    end
  end
end