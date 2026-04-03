# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Teams API', type: :request do
  include RolesHelper

  def auth_headers_for(user)
    token = JsonWebToken.encode(
      {
        id: user.id,
        name: user.name,
        full_name: user.full_name,
        role: user.role.name,
        institution_id: user.institution_id
      }
    )

    {
      'Authorization' => "Bearer #{token}",
      'Accept' => 'application/json'
    }
  end

  let!(:roles) { create_roles_hierarchy }
  let!(:institution) { create(:institution) }
  let!(:instructor) do
    User.create!(
      name: 'teamspecuser',
      email: 'teamspec@example.com',
      password: 'password',
      full_name: 'Team Spec User',
      institution: institution,
      role: roles[:instructor]
    )
  end
  let!(:course) { create(:course, instructor: instructor, institution: institution) }
  let!(:assignment) { create(:assignment, instructor: instructor, course: course) }
  let!(:assignment_team) { AssignmentTeam.create!(name: 'Alpha Team', parent_id: assignment.id) }
  let!(:course_team) { CourseTeam.create!(name: 'Beta Team', parent_id: course.id) }

  describe 'GET /teams' do
    it 'returns teams filtered by parent_id and types' do
      get '/teams',
          params: { parent_id: assignment.id, types: 'AssignmentTeam' },
          headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['id']).to eq(assignment_team.id)
      expect(json.first['name']).to eq('Alpha Team')
      expect(json.first['type']).to eq('AssignmentTeam')
      expect(json.first['parent_id']).to eq(assignment.id)
    end
  end
end
