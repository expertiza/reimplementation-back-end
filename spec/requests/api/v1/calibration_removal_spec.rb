# spec/requests/api/v1/calibration_removal_spec.rb

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration Participant Removal', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  let(:instructor) do
    User.create!(
      name: 'instructor1',
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor One',
      email: 'instructor1@example.com',
      institution: @institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'A1',
      instructor_id: instructor.id,
      course: Course.create!(name: 'C1', instructor: instructor, institution: @institution, directory_path: 'c1_dir'),
      directory_path: 'a1_dir',
      rounds_of_reviews: 1,
      max_team_size: 3
    )
  end

  let(:student) do
    User.create!(
      name: 'student1',
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student One',
      email: 'student1@example.com',
      institution: @institution
    )
  end

  let(:auth_headers) do
    token = JsonWebToken.encode({ id: instructor.id })
    { 'Authorization' => "Bearer #{token}" }
  end

  describe 'DELETE /assignments/:assignment_id/calibration_response_maps/:id' do
    it 'removes the calibration mapping and its associated responses' do
      # 1. Setup: Add a calibration participant
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: auth_headers
      expect(response).to have_http_status(:created)
      
      body = JSON.parse(response.body)
      map_id = body['response_map']['id']
      team_id = body['team']['id']
      
      # Ensure team of 1 was created
      expect(AssignmentTeam.find(team_id).participants.size).to eq(1)

      # 2. Begin review (simulates mock response creation)
      post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/begin", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(Response.where(map_id: map_id).count).to eq(1)

      # 3. Perform removal
      delete "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}", headers: auth_headers
      expect(response).to have_http_status(:ok)

      # 4. Verify everything is gone
      expect(ReviewResponseMap.find_by(id: map_id)).to be_nil
      expect(Response.where(map_id: map_id).count).to eq(0)
      # Team should be deleted because it's a team of 1 created for this calibration
      expect(AssignmentTeam.find_by(id: team_id)).to be_nil
    end

    it 'removes the mapping but keeps preexisting teams with other members' do
      # 1. Setup: Preexisting team of 2 students
      student2 = User.create!(name: 'student2', password: 'password', role_id: @roles[:student].id, full_name: 'S2', email: 's2@example.com', institution: @institution)
      team = AssignmentTeam.create!(name: 'PreexistingTeam', parent_id: assignment.id)
      p1 = AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
      p2 = AssignmentParticipant.create!(parent_id: assignment.id, user_id: student2.id, type: 'AssignmentParticipant', handle: student2.name)
      team.add_participant(p1)
      team.add_participant(p2)

      # 2. Add student1 for calibration (uses existing team)
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: auth_headers
      expect(response).to have_http_status(:created)
      
      body = JSON.parse(response.body)
      map_id = body['response_map']['id']
      expect(body['team']['id']).to eq(team.id)

      # 3. Perform removal
      delete "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}", headers: auth_headers
      expect(response).to have_http_status(:ok)

      # 4. Verify mapping is gone but team remains
      expect(ReviewResponseMap.find_by(id: map_id)).to be_nil
      expect(AssignmentTeam.find_by(id: team.id)).to be_present
      # Team size should be 2 again (though in calibration maps, normally only 1 student is added,
      # but if they were on a preexisting team, our code would use it)
      # Actually, our current code in `create` just reuse the team the participant is on.
      # When we `team.remove_participant(participant)`, p1 is removed. p2 remains.
      expect(AssignmentTeam.find(team.id).participants.size).to eq(1)
      expect(AssignmentTeam.find(team.id).participants.first.user_id).to eq(student2.id)
    end
  end
end
