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
        questionnaire: instance_double(Questionnaire, name: 'Updated Rubric', questionnaire_type: 'ReviewQuestionnaire'),
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

    it 'resets affected reviews when a review rubric mapping changes' do
      mapping = instance_double(AssignmentQuestionnaire)
      review_questionnaire = instance_double(Questionnaire, name: 'Updated Rubric', questionnaire_type: 'ReviewQuestionnaire')

      allow(AssignmentQuestionnaire).to receive(:find).with('1').and_return(mapping)
      allow(mapping).to receive_messages(
        id: 1,
        assignment_id: 2,
        questionnaire_id: 3,
        questionnaire: review_questionnaire,
        project_topic_id: 4,
        project_topic: nil,
        used_in_round: 1,
        notification_limit: 15,
        questionnaire_weight: nil
      )
      allow(mapping).to receive(:update) do
        allow(mapping).to receive(:questionnaire_id).and_return(5)
        true
      end
      expect(controller).to receive(:reset_reviews_for_mapping).with(
        assignment_id: 2,
        questionnaire_id: 3,
        project_topic_id: 4,
        used_in_round: 1,
        review_mapping: true
      )

      patch :update,
            params: {
              id: 1,
              assignment_questionnaire: { questionnaire_id: 5 }
            },
            format: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes a mapping' do
      mapping = instance_double(AssignmentQuestionnaire)
      allow(AssignmentQuestionnaire).to receive(:find).with('1').and_return(mapping)
      allow(mapping).to receive_messages(
        assignment_id: 2,
        questionnaire_id: 3,
        questionnaire: instance_double(Questionnaire, questionnaire_type: 'ReviewQuestionnaire'),
        project_topic_id: 4,
        used_in_round: 1
      )
      allow(mapping).to receive(:destroy)
      allow(controller).to receive(:reset_reviews_for_mapping)

      delete :destroy, params: { id: 1 }, format: :json

      expect(response).to have_http_status(:no_content)
    end
  end

  describe '#reset_reviews_for_mapping' do
    it 'deletes matching review responses and notifies reviewers' do
      assignment = create(:assignment)
      topic = create(:project_topic, assignment: assignment)
      reviewee_team = AssignmentTeam.create!(name: 'Security Team', parent_id: assignment.id, type: 'AssignmentTeam')
      other_team = AssignmentTeam.create!(name: 'UI Team', parent_id: assignment.id, type: 'AssignmentTeam')
      reviewer_user = create(:user, :student)
      reviewer = AssignmentParticipant.create!(
        user: reviewer_user,
        parent_id: assignment.id,
        type: 'AssignmentParticipant',
        handle: reviewer_user.name
      )
      matching_map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: reviewee_team.id,
        type: 'ReviewResponseMap'
      )
      other_map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: other_team.id,
        type: 'ReviewResponseMap'
      )
      matching_response = Response.create!(map_id: matching_map.id, round: 1, is_submitted: true)
      other_topic_response = Response.create!(map_id: other_map.id, round: 1, is_submitted: true)
      other_round_response = Response.create!(map_id: matching_map.id, round: 2, is_submitted: true)
      delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)

      SignedUpTeam.create!(project_topic: topic, team: reviewee_team, is_waitlisted: false)
      allow(RubricUpdateMailer).to receive(:with).and_return(
        instance_double(ActionMailer::Parameterized::MessageDelivery, review_redo_notification: delivery)
      )

      controller.send(
        :reset_reviews_for_mapping,
        assignment_id: assignment.id,
        questionnaire_id: 3,
        project_topic_id: topic.id,
        used_in_round: 1,
        review_mapping: true
      )

      expect(Response.exists?(matching_response.id)).to be(false)
      expect(Response.exists?(other_topic_response.id)).to be(true)
      expect(Response.exists?(other_round_response.id)).to be(true)
      expect(RubricUpdateMailer).to have_received(:with).with(response_map: matching_map, assignment: assignment)
      expect(delivery).to have_received(:deliver_later)
    end
  end
end
