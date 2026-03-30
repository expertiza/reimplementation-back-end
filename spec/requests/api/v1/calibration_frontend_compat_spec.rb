# spec/requests/api/v1/calibration_frontend_compat_spec.rb

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration Frontend Compatibility', type: :request do
  let!(:instructor) { User.find_by(name: 'instr_frontend') || create(:user, name: 'instr_frontend', role: Role.find_by(name: 'instructor') || create(:role, name: 'instructor')) }
  let!(:assignment) { create(:assignment, name: "Calibration Front #{Time.now.to_i}", instructor: instructor, course: create(:course, directory_path: "path_f_#{Time.now.to_i}")) }
  let!(:team) { create(:assignment_team, name: 'Calibration Team 1', assignment: assignment) }
  let!(:participant) { create(:assignment_participant, user: instructor, assignment: assignment) }
  
  let!(:calibration_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id: participant.id,
      reviewee_id: team.id,
      for_calibration: true
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:auth_header) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /assignments/:assignment_id/calibration_response_maps' do
    it 'returns review_status for the list (frontend compat)' do
      get "/assignments/#{assignment.id}/calibration_response_maps", headers: auth_header
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first).to have_key('review_status')
      expect(json.first['review_status']).to eq('not_started')
    end
  end

  describe 'GET /assignments/:assignment_id/calibration_reports/:id' do
    it 'returns per_item_summary and submitted_content (frontend compat)' do
      # Mock the questionnaire and items if needed, but the controller should handle empty cases
      get "/assignments/#{assignment.id}/calibration_reports/#{calibration_map.id}", headers: auth_header
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('per_item_summary')
      expect(json).to have_key('submitted_content')
      expect(json['submitted_content']).to have_key('hyperlinks')
      expect(json['submitted_content']).to have_key('files')
    end
  end
end
