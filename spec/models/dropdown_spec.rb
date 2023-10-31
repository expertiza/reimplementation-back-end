require 'rails_helper'

RSpec.describe Dropdown, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns an HTML string with the edit form for a question' do
        dropdown = Dropdown.new
        html = dropdown.edit(5)
        expect(html).to be_a(String)
      end
    end
  end

  describe "#view_question_text" do


    context "when given invalid inputs" do
      it "raises an error" do
        dropdown = Dropdown.new
        expect { dropdown.view_question_text(txt: nil, type: "Multiple Choice", weight: 1) }.to raise_error(StandardError)
      end
    end
  end

  describe '#complete' do
    context 'when count is provided' do
      it 'generates HTML code for a select input with the given count' do
        dropdown = Dropdown.new
        html = dropdown.complete(5)
        expect(html).to be_a(String)
      end
    end

    context 'when answer is provided' do
      it 'generates HTML code with the provided answer' do
        dropdown = Dropdown.new
        html = dropdown.complete(5, 2)
        expect(html).to be_a(String)
      end
    end

    context 'when answer is not provided' do
      it 'generates HTML code without any answer' do
        dropdown = Dropdown.new
        html = dropdown.complete(5)
        expect(html).to be_a(String)
      end
    end
  end

end