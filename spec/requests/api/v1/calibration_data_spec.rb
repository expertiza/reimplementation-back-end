# spec/requests/api/v1/calibration_data_spec.rb

require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Calibration API', type: :request do
  let!(:instructor) { create(:user, role: create(:role, name: 'instructor')) }
  let!(:assignment) { create(:assignment, name: 'Calibration Assignment', instructor: instructor) }
  let!(:team) { create(:assignment_team, name: 'Calibration Team 1', assignment: assignment) }
  let!(:participant) { create(:participant, user: instructor, assignment: assignment) }
  
  # Create a ReviewResponseMap for calibration (instructor's review)
  let!(:calibration_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id: participant.id,
      reviewee_id: team.id,
      calibration: true
    )
  end

  let!(:instructor_response) do
    Response.create!(
      response_map: calibration_map,
      is_submitted: true,
      additional_comment: 'Gold standard'
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  describe 'GET /assignments/:assignment_id/calibration_submissions' do
    it 'returns a list of calibration submissions' do
      get "/assignments/#{assignment.id}/calibration_submissions", headers: { 'Authorization' => Authorization }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['calibration_entries']).to be_an(Array)
      expect(json['calibration_entries'].first['team_id']).to eq(team.id)
    end
  end

  describe 'GET /assignments/:assignment_id/calibration_reviews/:team_id' do
    it 'returns comparison data between instructor and student reviews' do
      get "/assignments/#{assignment.id}/calibration_reviews/#{team.id}", headers: { 'Authorization' => Authorization }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('instructor_response')
      expect(json).to have_key('student_responses')
      expect(json).to have_key('summary')
      expect(json['instructor_response']['response_id']).to eq(instructor_response.id)
    end
  end
end
