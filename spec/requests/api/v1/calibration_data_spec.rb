# spec/requests/api/v1/calibration_data_spec.rb

require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration API', type: :request do
  let!(:instructor) { User.find_by(name: 'instr_unique') || create(:user, name: 'instr_unique', role: Role.find_by(name: 'instructor') || create(:role, name: 'instructor')) }
  let!(:assignment) { create(:assignment, name: "Calibration Assignment #{Time.now.to_i}", instructor: instructor, course: create(:course, directory_path: "path_#{Time.now.to_i}")) }
  let!(:team) { create(:assignment_team, name: 'Calibration Team 1', assignment: assignment) }
  let!(:participant) { create(:assignment_participant, user: instructor, assignment: assignment) }
  
  # Create a ReviewResponseMap for calibration (instructor's review)
  let!(:calibration_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id: participant.id,
      reviewee_id: team.id,
      for_calibration: true
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
  let(:auth_header) { "Bearer #{token}" }

  describe 'GET /assignments/:assignment_id/calibration_data' do
    it 'returns a list of calibration submissions' do
      get "/assignments/#{assignment.id}/calibration_data", headers: { 'Authorization' => auth_header }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['calibration_entries']).to be_an(Array)
      expect(json['calibration_entries'].first['team_id']).to eq(team.id)
    end
  end

  describe 'GET /assignments/:assignment_id/calibration_reviews/:team_id' do
    it 'returns comparison data between instructor and student reviews' do
      get "/assignments/#{assignment.id}/calibration_reviews/#{team.id}", headers: { 'Authorization' => auth_header }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('instructor_response')
      expect(json).to have_key('student_responses')
      expect(json).to have_key('summary')
      expect(json['instructor_response']['response_id']).to eq(instructor_response.id)
    end
  end
end
