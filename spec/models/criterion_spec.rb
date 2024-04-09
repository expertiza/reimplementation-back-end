require 'rails_helper'

# RSpec tests for the Criterion class, a type of ScoredQuestion
RSpec.describe Criterion, type: :model do
  # Setup for tests: defining a questionnaire and a criterion question associated with it
  let(:questionnaire) { Questionnaire.new(min_question_score: 0, max_question_score: 5) }
  let(:criterion) { Criterion.new(id: 1, question_type: 'Criterion', seq: 1.0, txt: 'test txt', weight: 1, questionnaire: questionnaire) }

  # Dummy answers for testing
  let(:answer_no_comments) { Answer.new(answer: 8) }
  let(:answer_comments) { Answer.new(answer: 3, comments: 'text comments') }

  # Test suite for the #view_question_text method
  describe '#view_question_text' do
    it 'returns the JSON' do
      # Calling the method and checking the returned JSON structure
      json = criterion.view_question_text
      expected_json = {
        text: 'test txt',  # The text of the question
        question_type: 'Criterion',  # The type of question
        weight: 1,  # The weight of the question
        score_range: '0 to 5'  # The score range, derived from the associated questionnaire
      }
      expect(json).to eq(expected_json)  # Asserting that the actual JSON matches the expected structure
    end
  end

  # Test suite for the #complete method
  describe '#complete' do
    it 'returns JSON without answer and no dropdown or scale specified' do
      # Testing completion without specifying dropdown or scale
      json = criterion.complete(0, nil, 0, 5)
      expected_json = {
        label: 'test txt'  # The label should only contain the question text
      }
      expect(json).to include(expected_json)  # Asserting the inclusion of the expected JSON
    end

    it 'returns JSON with a dropdown, including answer options' do
      # Testing completion with dropdown options
      json = criterion.complete(0, nil, 0, 5, 'dropdown')
      expected_options = (0..5).map { |score| { value: score, label: score.to_s } }  # Expected options for the dropdown
      expected_json = {
        label: 'test txt',  # The question text
        response_options: {  # The options for responding to the question in a dropdown format
          type: 'dropdown',
          comments: nil,
          current_answer: nil,
          options: expected_options,
        }
      }
      expect(json).to include(expected_json)  # Asserting the inclusion of the expected JSON
    end
  end

  # Test suite for the #dropdown_criterion_question method
  describe '#dropdown_criterion_question' do
    it 'returns JSON for a dropdown without an answer selected' do
      # Testing dropdown options without a selected answer
      json = criterion.dropdown_criterion_question(0, nil, 0, 5)
      expected_options = (0..5).map { |score| { value: score, label: score.to_s } }  # Expected options for the dropdown
      expected_json = {
        type: 'dropdown',  # The type of response input
        comments: nil,  # No comments
        current_answer: nil,  # No current answer
        options: expected_options,  # The options for the dropdown
      }
      expect(json).to eq(expected_json)  # Asserting that the actual JSON matches the expected structure
    end
  end

  # Test suite for the #scale_criterion_question method
  describe '#scale_criterion_question' do
    it 'returns JSON for a scale question without an answer selected' do
      # Testing scale question options without a selected answer
      json = criterion.scale_criterion_question(0, nil, 0, 5)
      expected_json = {
        type: 'scale',  # The type of response input
        min: 0,  # Minimum value for the scale
        max: 5,  # Maximum value for the scale
        comments: nil,  # No comments
        current_answer: nil,  # No current answer
        min_label: nil,  # No minimum label
        max_label: nil,  # No maximum label
        size: nil,  # No size specified
      }
      expect(json).to eq(expected_json)  # Asserting that the actual JSON matches the expected structure
    end
  end
end
