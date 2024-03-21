require 'rails_helper'

RSpec.describe Response, type: :model do
  let(:response_map) do
    ResponseMap.new(id: 1, reviewed_object_id: 1, reviewer_id: 1, reviewee_id: 2, type: 'ReviewResponseMap',
                    calibrate_to: false, team_reviewing_enabled: false, assignment_questionnaire_id: 1)
  end
  let(:response) do
    Response.new(id: 1, map_id: 1, additional_comment: 'comment 1', is_submitted: false, version_num: 1, round: 1,
                 visibility: 'private', response_map:)
  end
  let(:answer) { Answer.new(id: 1, answer: 5, comments: 'Answer comment', question_id: 1) }
  let(:question) { Question.new(id: 1, weight: 2) }
  let(:assignment_questionnaire) { AssignmentQuestionnaire.new(id: 1, assignment_id: 1, questionnaire_id: 1) }
  let(:params) do
    {
      map_id: 1,
      additional_comment: 'This is a sample comment',
      is_submitted: false,
      version_num: 1,
      round: 1,
      visibility: 'private',
      response_map: {
        id: 1,
        reviewed_object_id: 1,
        reviewer_id: 1,
        reviewee_id: 2,
        type: 'ReviewResponseMap',
        calibrate_to: false,
        team_reviewing_enabled: false,
        assignment_questionnaire_id: 1
      },
      scores: [
        { question_id: 1, answer: 5, comments: 'Answer 1 comments' },
        { question_id: 2, answer: 4, comments: 'Answer 2 comments' },
        { question_id: 3, answer: 3, comments: 'Answer 3 comments' }
      ]
    }
  end

  # Validations
  describe 'validations' do
    it 'map_id exist?' do
      expect(response.map_id).to eq(1)
    end
    it 'map_id is the same as response.response_map.id' do
      expect(response.map_id).to eq(response.response_map.id)
    end
    it 'Response_map should be an instance of the ResponseMap class' do
      response.response_map.should be_kind_of(ResponseMap)
    end
    it 'scores should be an array of the Answer classes' do
      response = create(:response)
      response.scores = create_list(:answer, 3, response:)
      expect(response.scores.length).to eq(3)
      expect(response.scores).to all(be_a(Answer))
      expect(response.scores).to be_an(ActiveRecord::Associations::CollectionProxy)
    end
  end

  # validate method
  describe 'Validate the incomming parameters' do
    # Assuming you have factories set up for your models
    # let(:response_map) { create(:response_map) }
    # let(:response) { build(:response, response_map: response_map) }

    context 'when creating a new response' do
      it 'validates not existing of response_map in database' do
        params = { map_id: 3 }
        response = Response.new
        response.validate(params, 'create')
        expect(response.errors[:response_map]).to include('Not found response map')
      end
      it 'validates creating a new response' do
        response = Response.new
        params[:map_id] = 1
        response.validate(params, 'create')
        expect(response.errors.full_messages.length).to eq(0)
      end
    end
    context 'when updating a response' do
      it 'validates updating the response' do
        id = 1
        response = Response.find(id)
        params1 = {}
        params1[:response] = params
        params1[:response][:is_submitted] = true
        response.validate(params1, 'update')
        expect(response.is_submitted).to eq(true)
      end
      it 'validates cannot update the submitted response' do
        id = 1
        response = Response.find(id)
        response.is_submitted = true
        params1 = {}
        params1[:response] = params
        response.validate(params1, 'update')
        expect(response.errors[:response]).to include('Already submitted.')
      end
    end
  end

  # #set_content method
  describe '#set_content' do
    it 'sets the response content based on provided response id' do
      params = { id: 1 }
      response = Response.find(params[:id])
      response.set_content(params, 'show')
      expect(response.errors.full_messages.length).to eq(0)
    end
  end
end
