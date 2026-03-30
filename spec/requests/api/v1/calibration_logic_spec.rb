# spec/requests/api/v1/calibration_logic_spec.rb

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration Logic (Workarounds)', type: :request do
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

  let(:course) do
    Course.create!(
      name: 'C1',
      instructor: instructor,
      institution: @institution,
      directory_path: 'c1_dir'
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'A1',
      instructor_id: instructor.id,
      course: course,
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

  describe 'Testing around limitations (No frontend, No submission UI)' do
    
    it 'handles teams with no submitted_hyperlinks (Defaulting to empty array)' do
      # Setup: Student on a team but NO submission made yet.
      team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id, type: 'AssignmentTeam')
      # No submitted_hyperlinks set or nil.
      
      # Instructor participant
      instructor_p = AssignmentParticipant.create!(parent_id: assignment.id, user_id: instructor.id, type: 'AssignmentParticipant', handle: instructor.name)
      
      # Calibration map
      ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: instructor_p.id,
        reviewee_id: team.id,
        for_calibration: true
      )

      get "/assignments/#{assignment.id}/calibration_data", headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      entry = json['calibration_entries'].find { |e| e['team_id'] == team.id }
      expect(entry['submitted_content']['hyperlinks']).to eq([])
    end

    it 'handles scenarios where instructor has not yet created a response (begin link scenario)' do
      team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id, type: 'AssignmentTeam')
      instructor_p = AssignmentParticipant.create!(parent_id: assignment.id, user_id: instructor.id, type: 'AssignmentParticipant', handle: instructor.name)
      
      map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: instructor_p.id,
        reviewee_id: team.id,
        for_calibration: true
      )

      # No Response record exists for this map.
      
      # 1. Check calibration_data view: instructor_review should be nil
      get "/assignments/#{assignment.id}/calibration_data", headers: auth_headers
      json = JSON.parse(response.body)
      entry = json['calibration_entries'].find { |e| e['team_id'] == team.id }
      expect(entry['instructor_review']).to be_nil

      # 2. Check /begin endpoint: should suggest "edit" because of mock auto-creation
      post "/assignments/#{assignment.id}/calibration_response_maps/#{map.id}/begin", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['redirect_to']).to include("/assignments/edit/#{assignment.id}/calibration/#{map.id}")
    end

    it 'handles student reviews that are not yet submitted' do
      team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id, type: 'AssignmentTeam')
      instructor_p = AssignmentParticipant.create!(parent_id: assignment.id, user_id: instructor.id, type: 'AssignmentParticipant', handle: instructor.name)
      ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: instructor_p.id, reviewee_id: team.id, for_calibration: true)
      
      # Student participant and their review map (not for calibration)
      student_p = AssignmentParticipant.create!(parent_id: assignment.id, user_id: student.id, type: 'AssignmentParticipant', handle: student.name)
      student_map = ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: student_p.id, reviewee_id: team.id, for_calibration: false)
      
      # Student started a response but didn't submit it
      Response.create!(map_id: student_map.id, is_submitted: false)

      get "/assignments/#{assignment.id}/calibration_data", headers: auth_headers
      json = JSON.parse(response.body)
      entry = json['calibration_entries'].find { |e| e['team_id'] == team.id }
      
      expect(entry['student_reviews'].size).to eq(1)
      expect(entry['student_reviews'].first['is_submitted']).to be false
    end

    it 'handles missing rubric/questionnaire gracefully in comparison view' do
      # AssignmentsController#calibration_reviews expects a ReviewQuestionnaire to exist for the assignment
      team = AssignmentTeam.create!(name: 'Team1', parent_id: assignment.id, type: 'AssignmentTeam')
      
      # If no questionnaire exists, rubric_items will be empty.
      get "/assignments/#{assignment.id}/calibration_reviews/#{team.id}", headers: auth_headers
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['rubric']).to eq([])
      expect(json['summary']).to eq({})
    end
  end
end
