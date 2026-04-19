require 'rails_helper'

RSpec.describe AssignmentQuestionnairesController, type: :controller do
  before do
    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe 'GET #index' do
    it 'lists mappings for an assignment' do
      mapping = instance_double(
        AssignmentQuestionnaire,
        id: 1,
        assignment_id: 2,
        questionnaire_id: 3,
        questionnaire: instance_double(Questionnaire, name: 'Review Rubric'),
        project_topic_id: 4,
        project_topic: instance_double(ProjectTopic, topic_name: 'Security'),
        used_in_round: 1,
        notification_limit: 15,
        questionnaire_weight: 100
      )

      relation = double('AssignmentQuestionnaire::Relation')
      allow(AssignmentQuestionnaire).to receive(:includes).with(:questionnaire, :project_topic).and_return(relation)
      allow(relation).to receive(:where).with(assignment_id: '2').and_return([mapping])

      get :index, params: { assignment_id: 2 }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([
        {
          'id' => 1,
          'assignment_id' => 2,
          'questionnaire_id' => 3,
          'questionnaire_name' => 'Review Rubric',
          'project_topic_id' => 4,
          'project_topic_name' => 'Security',
          'used_in_round' => 1,
          'notification_limit' => 15,
          'questionnaire_weight' => 100
        }
      ])
    end
  end

  describe 'POST #create' do
    it 'creates a topic rubric mapping' do
      mapping = instance_double(AssignmentQuestionnaire, save: true)
      allow(AssignmentQuestionnaire).to receive(:new).and_return(mapping)
      allow(mapping).to receive_messages(
        id: 1,
        assignment_id: 2,
        questionnaire_id: 3,
        questionnaire: instance_double(Questionnaire, name: 'Review Rubric'),
        project_topic_id: 4,
        project_topic: instance_double(ProjectTopic, topic_name: 'Security'),
        used_in_round: 1,
        notification_limit: 15,
        questionnaire_weight: nil
      )

      post :create,
           params: {
             assignment_questionnaire: {
               assignment_id: 2,
               questionnaire_id: 3,
               project_topic_id: 4,
               used_in_round: 1
             }
           },
           format: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['project_topic_id']).to eq(4)
    end

    it 'returns validation errors' do
      errors = instance_double(ActiveModel::Errors, full_messages: ['Project topic must belong to the same assignment'])
      mapping = instance_double(AssignmentQuestionnaire, save: false, errors: errors)
      allow(AssignmentQuestionnaire).to receive(:new).and_return(mapping)

      post :create,
           params: {
             assignment_questionnaire: {
               assignment_id: 2,
               questionnaire_id: 3,
               project_topic_id: 4
             }
           },
           format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq(
        'errors' => ['Project topic must belong to the same assignment']
      )
    end
  end

  describe 'PATCH #update' do
    it 'updates a mapping' do
      mapping = instance_double(AssignmentQuestionnaire)
      allow(AssignmentQuestionnaire).to receive(:find).with('1').and_return(mapping)
      allow(mapping).to receive(:update).and_return(true)
      allow(mapping).to receive_messages(
        id: 1,
        assignment_id: 2,
        questionnaire_id: 5,
        questionnaire: instance_double(Questionnaire, name: 'Updated Rubric'),
        project_topic_id: 4,
        project_topic: nil,
        used_in_round: nil,
        notification_limit: 15,
        questionnaire_weight: nil
      )

      patch :update,
            params: {
              id: 1,
              assignment_questionnaire: { questionnaire_id: 5 }
            },
            format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['questionnaire_id']).to eq(5)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes a mapping' do
      mapping = instance_double(AssignmentQuestionnaire)
      allow(AssignmentQuestionnaire).to receive(:find).with('1').and_return(mapping)
      allow(mapping).to receive(:destroy)

      delete :destroy, params: { id: 1 }, format: :json

      expect(response).to have_http_status(:no_content)
    end
  end
end
