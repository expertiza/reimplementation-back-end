# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Courses API', type: :request do
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
      name: 'coursespecuser',
      email: 'coursespec@example.com',
      password: 'password',
      full_name: 'Course Spec User',
      institution: institution,
      role: roles[:instructor]
    )
  end
  let!(:course) { create(:course, name: 'CSC 517', instructor: instructor, institution: institution) }
  let!(:assignment) { create(:assignment, name: 'Assignment 1', instructor: instructor, course: course) }

  describe 'GET /courses' do
    it 'returns courses with nested assignments' do
      get '/courses', headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      course_json = json.find { |record| record['id'] == course.id }

      expect(course_json).to be_present
      expect(course_json['name']).to eq('CSC 517')
      expect(course_json['assignments']).to be_an(Array)
      expect(course_json['assignments'].map { |record| record['id'] }).to include(assignment.id)
    end
  end
end
