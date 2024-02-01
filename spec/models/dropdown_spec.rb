require 'rails_helper'

RSpec.describe Dropdown, type: :model do
  describe '#edit' do
    context 'when given a count' do
      it 'returns a JSON object with the edit form for a question' do
        dropdown = Dropdown.new
        json_result = dropdown.edit(5)

        expected_result = {
          edit_form: '<div>Edit form content here</div>'
        }
        expect(json_result).to eq(expected_result)
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
      it 'generates JSON code for a select input with the given count' do
        dropdown = Dropdown.new
        json_result = dropdown.complete(5)

        expected_result = {
          select_input: '<select>Options for question count 5</select>'
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when answer is provided' do
      it 'generates JSON code with the provided answer' do
        dropdown = Dropdown.new
        json_result = dropdown.complete(5, 2)

        expected_result = {
          select_input: '<select>Options for question count 5</select>',
          answer: 2
        }
        expect(json_result).to eq(expected_result)
      end
    end

    context 'when answer is not provided' do
      it 'generates JSON code without any answer' do
        dropdown = Dropdown.new
        json_result = dropdown.complete(5)

        expected_result = {
          select_input: '<select>Options for question count 5</select>',
          answer: nil
        }
        expect(json_result).to eq(expected_result)
      end
    end
  end
end