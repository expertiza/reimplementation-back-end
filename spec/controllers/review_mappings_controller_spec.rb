require 'rails_helper'

RSpec.describe ReviewMappingsController, type: :controller do
  controller do
    include JwtToken
    include Authorization

    skip_before_action :authorize
    skip_before_action :set_assignment
    skip_before_action :authenticate_request!
  end

  before do
    @routes = Rails.application.routes
    Rails.application.routes.draw do
      resources :assignments do
        resources :review_mappings, except: [:index, :show, :new, :edit, :create, :update] do
          collection do
            post 'assign_round_robin'
            post 'assign_random'
            post 'assign_from_csv'
            post 'request_review_fewest'
            post 'set_calibration_artifact'
            delete 'delete_all_for_reviewer/:reviewer_id', action: :delete_all_for_reviewer
            patch 'grade_review/:mapping_id', action: :grade_review
          end
        end
      end
    end
  end

  let(:assignment) { create(:assignment) }
  let(:reviewer) { create(:assignment_participant, assignment: assignment) }
  let(:team) { create(:team, assignment: assignment) }
  let!(:response_map) do
    ReviewResponseMap.create!(
      reviewer: reviewer,
      reviewee: team,
      reviewed_object_id: assignment.id
    )
  end

  let(:handler) { instance_double(ReviewMappingHandler) }

  before do
    allow(ReviewMappingHandler).to receive(:new).and_return(handler)
    allow_any_instance_of(Authorization).to receive(:authorize).and_return(true)
    # Stub current_user and auth_token
    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow(controller).to receive(:current_user).and_return(reviewer.user)
    allow(controller).to receive(:auth_token).and_return({ id: reviewer.user_id })
    # Stub set_assignment to set the assignment instance variable
    controller.instance_variable_set(:@assignment, assignment)
  end

  after do
    Rails.application.reload_routes!
  end

  describe 'POST #assign_round_robin' do
    it 'creates round-robin assignments' do
      expect(handler).to receive(:assign_statically).with(ReviewMappingStrategies::RoundRobinStrategy)
      post :assign_round_robin, params: { assignment_id: assignment.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'Round-robin assignments created'
      })
    end
  end

  describe 'POST #assign_random' do
    it 'creates random assignments' do
      expect(handler).to receive(:assign_random)
      post :assign_random, params: { assignment_id: assignment.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'Random assignments created'
      })
    end
  end

  describe 'POST #assign_from_csv' do
    it 'creates assignments from CSV' do
      csv_path = Rails.root.join('spec/fixtures/files/sample_assignments.csv')
      csv_file = fixture_file_upload(csv_path, 'text/csv')
      expect(handler).to receive(:assign_from_csv).with(instance_of(String))
      post :assign_from_csv, params: { assignment_id: assignment.id, csv: csv_file }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'CSV-based assignments created'
      })
    end
  end

  describe 'POST #request_review_fewest' do
    it 'assigns dynamic review to reviewer' do
      mapping = double('ReviewResponseMap', id: 42)
      expect(handler).to receive(:assign_dynamically)
        .with(ReviewMappingStrategies::LeastReviewedSubmissionStrategy, reviewer)
        .and_return(mapping)

      post :request_review_fewest, params: { assignment_id: assignment.id, reviewer_id: reviewer.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'mapping_id' => 42
      })
    end
  end

  describe 'POST #set_calibration_artifact' do
    it 'assigns a calibration review' do
      reviewer_double = reviewer
      team = create(:team, assignment: assignment)
      mapping = double('ReviewResponseMap', id: 99)

      allow(AssignmentParticipant).to receive(:find).with(reviewer_double.id.to_s).and_return(reviewer_double)
      allow(AssignmentTeam).to receive(:find).with(team.id.to_s).and_return(team)
      expect(handler).to receive(:assign_calibration_review).with(reviewer_double, team).and_return(mapping)

      post :set_calibration_artifact, params: { assignment_id: assignment.id, reviewer_id: reviewer.id, submission_id: team.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'mapping_id' => 99
      })
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes a mapping' do
      allow_any_instance_of(Authorization).to receive(:authorize).and_return(true)
      expect(handler).to receive(:delete_review_mapping).with(response_map.id.to_s)
      delete :destroy, params: { assignment_id: assignment.id, id: response_map.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'Mapping deleted'
      })
    end
  end

  describe 'DELETE #delete_all_for_reviewer' do
    it 'deletes all mappings for a reviewer' do
      allow_any_instance_of(Authorization).to receive(:authorize).and_return(true)
      expect(handler).to receive(:delete_all_reviews_for).with(reviewer)
      delete :delete_all_for_reviewer, params: { assignment_id: assignment.id, reviewer_id: reviewer.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'All mappings for reviewer deleted'
      })
    end
  end

  describe 'PATCH #grade_review' do
    it 'grades a review' do
      allow_any_instance_of(Authorization).to receive(:authorize).and_return(true)
      expect(handler).to receive(:grade_review).with(response_map, grade: '95', comment: 'Good work')
      patch :grade_review, params: { assignment_id: assignment.id, mapping_id: response_map.id, grade: 95, comment: 'Good work' }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'status' => 'ok',
        'message' => 'Review graded'
      })
    end
  end
end
