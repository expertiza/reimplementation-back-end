# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'CalibrationResponseMaps', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode({ id: user.id })
    { 'Authorization' => "Bearer #{token}" }
  end

  let(:instructor) do
    User.create!(
      name: "instructor_#{Time.now.to_i}_#{rand(1000)}",
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor One',
      email: "instructor_#{Time.now.to_i}_#{rand(1000)}@example.com",
      institution: @institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: "A1_#{Time.now.to_i}_#{rand(1000)}",
      instructor_id: instructor.id,
      course: Course.create!(name: "C1_#{Time.now.to_i}_#{rand(1000)}", instructor: instructor, institution: @institution, directory_path: "c1_dir_#{Time.now.to_i}_#{rand(1000)}"),
      directory_path: "a1_dir_#{Time.now.to_i}_#{rand(1000)}",
      rounds_of_reviews: 1,
      max_team_size: 3
    )
  end

  let(:student) do
    User.create!(
      name: "student_#{Time.now.to_i}_#{rand(1000)}",
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student One',
      email: "student_#{Time.now.to_i}_#{rand(1000)}@example.com",
      institution: @institution
    )
  end

  it 'automatically creates a team of 1 for a student not on a team' do
    headers = auth_headers_for(instructor)
    # Student exists as a user, but NOT as a participant or team member yet
    # Actually, CalibrationResponseMapsController#create finds or creates the participant.
    
    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.to change(AssignmentTeam, :count).by(1)
      .and change(TeamsParticipant, :count).by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body['team']).to be_present
    expect(body['team']['id']).to be_present
    
    # Verify the participant is in the team
    participant_id = body['participant']['id']
    team_id = body['team']['id']
    expect(TeamsParticipant.exists?(participant_id: participant_id, team_id: team_id)).to be true
  end

  it 'creates (or reuses) participant and creates a for_calibration response map (201)' do
    # Create a team for the student
    team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id)
    AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
    TeamsParticipant.create!(user_id: student.id, team_id: team.id, participant_id: AssignmentParticipant.last.id)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: auth_headers_for(instructor)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)

    expect(body['participant']).to be_present
    expect(body['participant']['user']).to be_present
    expect(body['participant']['user']['name']).to eq(student.name)

    expect(body['response_map']).to be_present
    expect(body['response_map']['for_calibration']).to eq(true)
    expect(body['response_map']['reviewed_object_id']).to eq(assignment.id)

    # Some clients expect a team-like payload with hyperlinks always present.
    expect(body['team']).to be_present
    # Mock submission will add a hyperlink
    expect(body['team']['hyperlinks']).to include('https://github.com/expertiza/reimplementation')
  end

  it 'is idempotent for participant and response_map' do
    headers = auth_headers_for(instructor)
    # Create a team for the student
    team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id)
    # Important: the user must be on the team!
    AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
    TeamsParticipant.create!(user_id: student.id, team_id: team.id, participant_id: AssignmentParticipant.last.id)
    
    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.to change(AssignmentParticipant, :count).by(1) # only instructor participant needs to be created, student already exists
                                               .and change(ResponseMap, :count).by(1)

    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.not_to change(AssignmentParticipant, :count)

    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.not_to change(ResponseMap, :count)
  end

  it 'returns 404 for unknown username' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: 'does_not_exist' },
         headers: auth_headers_for(instructor)

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body)
    expect(body['error']).to match(/Unknown username/)
  end

  it 'forbids students (403)' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: auth_headers_for(student)

    expect(response).to have_http_status(:forbidden)
  end

  it 'lists calibration response maps for the instructor (200)' do
    headers = auth_headers_for(instructor)
    team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id)
    AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
    TeamsParticipant.create!(user_id: student.id, team_id: team.id, participant_id: AssignmentParticipant.last.id)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: headers
    expect(response).to have_http_status(:created)

    get "/assignments/#{assignment.id}/calibration_response_maps", headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body).to be_an(Array)
    expect(body.length).to eq(1)
    expect(body.first['for_calibration']).to eq(true)
    expect(body.first.dig('reviewee', 'users', 0, 'name')).to eq(student.name)
  end

  it 'returns routing info for begin (200)' do
    headers = auth_headers_for(instructor)
    team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id)
    AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
    TeamsParticipant.create!(user_id: student.id, team_id: team.id, participant_id: AssignmentParticipant.last.id)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: headers
    expect(response).to have_http_status(:created)
    created = JSON.parse(response.body)
    map_id = created.dig('response_map', 'id')
    expect(map_id).to be_present

    post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/begin", headers: headers
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['map_id']).to eq(map_id)
    # The mock will now automatically create a response if none exists, leading to the calibration view.
    expect(body['redirect_to']).to eq("/assignments/edit/#{assignment.id}/calibration/#{map_id}")
  end

  it 'returns edit routing info for begin when response exists (200)' do
    headers = auth_headers_for(instructor)
    team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id)
    AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
    TeamsParticipant.create!(user_id: student.id, team_id: team.id, participant_id: AssignmentParticipant.last.id)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: headers
    expect(response).to have_http_status(:created)
    created = JSON.parse(response.body)
    map_id = created.dig('response_map', 'id')

    # Create a response for the map
    Response.create!(map_id: map_id, is_submitted: false)

    post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/begin", headers: headers
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['redirect_to']).to eq("/assignments/edit/#{assignment.id}/calibration/#{map_id}")
  end
end
