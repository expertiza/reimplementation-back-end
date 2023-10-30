require 'rails_helper'

RSpec.describe Dropdown, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns an HTML string with the edit form for a question' do
        dropdown = Dropdown.new
        html = dropdown.edit(count: 5)
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end
  end

  describe "#view_question_text" do
    context "when given valid inputs" do
      it "returns the HTML code for displaying the question text, type, weight, and dash" do
        dropdown = Dropdown.new
        html = dropdown.view_question_text(txt: "Question 1", type: "Multiple Choice", weight: 1)
        expect(html).to eq('<TR><TD align="left">Question 1</TD><TD align="left">Multiple Choice</TD><td align="center">1</TD><TD align="center">&mdash;</TD></TR>')
      end
    end

    context "when given invalid inputs" do
      it "raises an error" do
        dropdown = Dropdown.new
        expect { dropdown.view_question_text(txt: nil, type: "Multiple Choice", weight: 1) }.to raise_error(StandardError)
        # Add similar expectations for other scenarios
      end
    end
  end

  describe '#complete' do
    context 'when count is provided' do
      it 'generates HTML code for a select input with the given count' do
        dropdown = Dropdown.new
        html = dropdown.complete(count: 5)
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end

    context 'when answer is provided' do
      it 'generates HTML code with the provided answer' do
        dropdown = Dropdown.new
        html = dropdown.complete(count: 5, answer: "Option 2")
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end

    context 'when answer is not provided' do
      it 'generates HTML code without any answer' do
        dropdown = Dropdown.new
        html = dropdown.complete(count: 5)
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end
  end

  describe '#complete_for_alternatives' do
    context 'when given an array of alternatives and an answer' do
      it 'returns a string of HTML options with the selected alternative marked' do
        dropdown = Dropdown.new
        html = dropdown.complete_for_alternatives(
          alternatives: ["Option 1", "Option 2", "Option 3"],
          answer: "Option 2"
        )
        expect(html).to eq('<option value="Option 1">Option 1</option><option value="Option 2" selected>Option 2</option><option value="Option 3">Option 3</option>')
      end
    end
  end

  describe '#view_completed_question' do
    context 'when given a count and an answer' do
      it 'returns the formatted HTML for a completed question' do
        dropdown = Dropdown.new
        html = dropdown.view_completed_question(count: 1, answer: "Option 1")
        expect(html).to be_a(String)
        # You may add more specific expectations on the HTML structure if needed
      end
    end
  end
end