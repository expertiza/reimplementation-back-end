require 'rails_helper'

RSpec.describe Scale, type: :model do

  subject { Scale.new }

  before do
    subject.txt = "Rate your experience"
    subject.type = "Scale"
    subject.weight = 1
    subject.min_label = "Poor"
    subject.max_label = "Excellent"
    subject.min_question_score = 1
    subject.max_question_score = 5
    subject.answer = 3
  end

  describe "#edit" do

    it 'returns a JSON object with question text, type, weight, and score range' do
      scale = Scale.new(txt: 'Scale Question', type: 'scale', weight: 2, min_question_score: 0, max_question_score: 10)

      json_result = scale.edit

      expected_result = {
        form: true,
        label: "Question:",
        input_type: "text",
        input_name: "question",
        input_value: "Scale Question",
        min_question_score: 0,
        max_question_score: 10,
        weight: 2,
        type: 'scale'
      }.to_json
      expect(json_result).to eq(expected_result)
    end
  end

  describe "#view_question_text" do
    it "returns JSON containing the question text" do
      expected_json = {
        text: "Rate your experience",
        type: "Scale",
        weight: 1,
        score_range: "Poor 1 to 5 Excellent"
      }.to_json
      expect(subject.view_question_text).to eq(expected_json)
    end
  end

  describe "#complete" do
    it "returns JSON with scale options" do
      expected_json = { scale_options: [
        { value: 1, selected: false },
        { value: 2, selected: false },
        { value: 3, selected: true },
        { value: 4, selected: false },
        { value: 5, selected: false }
      ] }.to_json
      expect(subject.complete).to eq(expected_json)
    end
  end

  describe "#view_completed_question" do
    context "when the question has been answered" do
      it "returns JSON with the count, answer, and questionnaire_max" do
        options = { count: 10, answer: 3, questionnaire_max: 50 }
        expected_json = options.to_json
        expect(subject.view_completed_question(options)).to eq(expected_json)
      end
    end

    context "when the question has not been answered" do
      it "returns a message indicating the question was not answered" do
        expected_json = { message: "Question not answered." }.to_json
        expect(subject.view_completed_question).to eq(expected_json)
      end
    end
  end
end