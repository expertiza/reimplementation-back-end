require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  describe '#calculate_score' do
    let(:correct_question) { double("Question", correct_answer: "A", score_value: 10) }
    let(:wrong_question)   { double("Question", correct_answer: "B", score_value: 5) }
    let(:response1) { double("Response", question: correct_question, skipped: false, submitted_answer: "A") }
    let(:response2) { double("Response", question: wrong_question, skipped: false, submitted_answer: "A") }
    let(:response3) { double("Response", question: wrong_question, skipped: true, submitted_answer: nil) }
    let(:response_map) { ResponseMap.new }

    before do
      # Stub the responses method to return our dummy responses
      allow(response_map).to receive(:responses).and_return([response1, response2, response3])
    end

    it 'calculates the total score based on correct, non-skipped responses' do
      # Only response1 is correct and not skipped → score = 10
      expect(response_map.calculate_score).to eq(10)
    end
  end

  describe '#find_or_initialize_response' do
    let(:response_map) { ResponseMap.create!(reviewer_id: 1, reviewee_id: 2, reviewed_object_id: 3) }
    let(:question_id) { 1 }

    it 'returns an existing response if found' do
      existing_response = Response.create!(response_map_id: response_map.id, question_id: question_id, submitted_answer: "Test")
      found_response = response_map.send(:find_or_initialize_response, response_map.id, question_id)
      expect(found_response).to eq(existing_response)
    end

    it 'initializes a new response if none exists' do
      Response.where(response_map_id: response_map.id, question_id: question_id).delete_all
      new_response = response_map.send(:find_or_initialize_response, response_map.id, question_id)
      expect(new_response).to be_new_record
      expect(new_response.question_id).to eq(question_id)
      expect(new_response.response_map_id).to eq(response_map.id)
    end
  end

  describe '#get_score' do
    it 'returns the score attribute of the response map' do
      response_map = ResponseMap.new
      response_map.score = 85
      expect(response_map.get_score).to eq(85)
    end
  end

  describe '#process_answers' do
    # Create a dummy question in the test database for processing answers.
    let!(:question) {
      Question.create!(txt: "What is Ruby?", correct_answer: "A", score_value: 10, skippable: false)
    }
    let(:response_map) { ResponseMap.create!(reviewer_id: 1, reviewee_id: 2, reviewed_object_id: 3) }
    let(:valid_answer) { { question_id: question.id, answer_value: "A", skipped: false } }
    let(:invalid_answer) { { question_id: question.id, answer_value: "B", skipped: false } }
    let(:skipped_answer) { { question_id: question.id, answer_value: nil, skipped: true } }

    context 'when the answer is correct' do
      it 'returns the score for the answer' do
        score = response_map.process_answers([valid_answer])
        expect(score).to eq(10)
      end
    end

    context 'when the answer is incorrect' do
      it 'returns zero score for the answer' do
        score = response_map.process_answers([invalid_answer])
        expect(score).to eq(0)
      end
    end

    context 'when the question is skipped' do
      it 'returns zero score' do
        score = response_map.process_answers([skipped_answer])
        expect(score).to eq(0)
      end
    end
  end

  describe '.build_response_map' do
    # Build a new ResponseMap instance for a student given a questionnaire
    let(:student_id) { 2 }
    let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: 1) }
    let(:questionnaire) {
      # Assuming Questionnaire has an assignment_id field, if not, stub assignment method as needed.
      Questionnaire.create!(name: "Test Quiz", instructor_id: 1,
                            min_question_score: 0, max_question_score: 10,
                            questionnaire_type: "Quiz", private: false,
                            assignment_id: assignment.id)
    }

    it 'builds a response map with correct attributes' do
      response_map = ResponseMap.build_response_map(student_id, questionnaire)
      expect(response_map.reviewee_id).to eq(student_id)
      expect(response_map.reviewer_id).to eq(questionnaire.assignment.instructor_id)
      expect(response_map.reviewed_object_id).to eq(questionnaire.id)
    end
  end
end
