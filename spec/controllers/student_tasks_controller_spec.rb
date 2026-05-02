require 'rails_helper'

RSpec.describe StudentTasksController, type: :controller do
  before do
    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe 'GET #rubric_for' do
    let(:response_map) { instance_double(ReviewResponseMap) }
    let(:assignment) { instance_double(Assignment) }
    let(:questionnaire) { instance_double(Questionnaire, name: 'Security Review Rubric') }
    let(:assignment_questionnaire) do
      instance_double(
        AssignmentQuestionnaire,
        id: 10,
        questionnaire_id: 20,
        questionnaire: questionnaire,
        project_topic_id: 30,
        used_in_round: 1
      )
    end

    it 'returns the rubric selected for a response map' do
      allow(ResponseMap).to receive(:find).with('5').and_return(response_map)
      allow(response_map).to receive(:response_assignment).and_return(assignment)
      allow(assignment)
        .to receive(:assignment_questionnaire_for_response_map)
        .with(response_map, round: 1)
        .and_return(assignment_questionnaire)

      get :rubric_for, params: { response_map_id: 5, round: 1 }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'assignment_questionnaire_id' => 10,
        'questionnaire_id' => 20,
        'questionnaire_name' => 'Security Review Rubric',
        'project_topic_id' => 30,
        'used_in_round' => 1
      )
    end

    it 'returns not found when no rubric can be resolved' do
      allow(ResponseMap).to receive(:find).with('5').and_return(response_map)
      allow(response_map).to receive(:response_assignment).and_return(assignment)
      allow(assignment)
        .to receive(:assignment_questionnaire_for_response_map)
        .with(response_map, round: nil)
        .and_return(nil)

      get :rubric_for, params: { response_map_id: 5 }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq(
        'error' => 'No review rubric found for this response map.'
      )
    end
  end
end
