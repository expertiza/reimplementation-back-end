# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Users API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: "Test Institution")
  end

  let(:student_role) { @roles[:student] }
  let(:instructor_role) { @roles[:instructor] }

  let(:instructor) do
    User.create!(
      name: 'instructor_test',
      password: 'password123',
      role_id: instructor_role.id,
      full_name: 'Instructor Test',
      email: 'instructor@example.com',
      institution: @institution
    )
  end

  let(:student) do
    User.create!(
      name: 'student_test',
      password: 'password123',
      role_id: student_role.id,
      full_name: 'Student Test',
      email: 'student@example.com',
      institution: @institution
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /users' do
    it 'returns 200 with list of users when authenticated' do
      get '/users', headers: headers

      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to be_an(Array)

      # Verify instructor is in list
      instructor_data = json_response.find { |u| u['id'] == instructor.id }
      expect(instructor_data).to be_present
      expect(instructor_data['name']).to eq(instructor.name)
      expect(instructor_data['email']).to eq(instructor.email)
      expect(instructor_data['full_name']).to eq(instructor.full_name)
      expect(instructor_data['role']).to be_a(Hash)
      expect(instructor_data['role']['id']).to eq(instructor_role.id)

      # Verify sensitive data is not included
      expect(instructor_data).not_to have_key('password_digest')
      expect(instructor_data).not_to have_key('password')
    end

    it 'returns 401 when not authenticated' do
      get '/users'

      expect(response.status).to eq(401)
    end

    it 'returns payload with all users' do
      # Create multiple users
      user1 = instructor
      user2 = student

      get '/users', headers: headers

      json_response = JSON.parse(response.body)
      user_ids = json_response.map { |u| u['id'] }

      expect(user_ids).to include(user1.id, user2.id)
    end
  end

  describe 'GET /users/:id' do
    it 'returns 200 with user data for existing user' do
      get "/users/#{student.id}", headers: headers

      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)

      expect(json_response['id']).to eq(student.id)
      expect(json_response['name']).to eq(student.name)
      expect(json_response['email']).to eq(student.email)
      expect(json_response['full_name']).to eq(student.full_name)
      expect(json_response['role']).to be_a(Hash)
      expect(json_response['role']['id']).to eq(student_role.id)

      # Verify sensitive data is not included
      expect(json_response).not_to have_key('password_digest')
      expect(json_response).not_to have_key('password')
    end

    it 'returns 404 for non-existent user' do
      get '/users/999999', headers: headers

      expect(response.status).to eq(404)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to be_present
    end

    it 'returns 401 when not authenticated' do
      get "/users/#{student.id}"

      expect(response.status).to eq(401)
    end

    it 'includes institution data in response' do
      get "/users/#{instructor.id}", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response['institution']).to be_a(Hash)
      expect(json_response['institution']['id']).to eq(@institution.id)
      expect(json_response['institution']['name']).to eq(@institution.name)
    end

    it 'includes parent field with nil when no parent' do
      get "/users/#{student.id}", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response['parent']).to eq({ 'id' => nil, 'name' => nil })
    end
  end

  describe 'POST /users' do
    it 'creates a user with valid parameters' do
      user_params = {
        user: {
          name: 'new_user',
          email: 'newuser@example.com',
          full_name: 'New User',
          password: 'securepass123',
          password_confirmation: 'securepass123',
          role_id: student_role.id,
          institution_id: @institution.id
        }
      }

      post '/users', params: user_params, headers: headers

      expect(response.status).to eq(201)
      json_response = JSON.parse(response.body)

      expect(json_response['name']).to eq('new_user')
      expect(json_response['email']).to eq('newuser@example.com')
      expect(json_response['full_name']).to eq('New User')
      expect(json_response).not_to have_key('password_digest')
    end

    it 'returns 422 when password is too short' do
      user_params = {
        user: {
          name: 'bad_user',
          email: 'bad@example.com',
          full_name: 'Bad User',
          password: '123',
          password_confirmation: '123',
          role_id: student_role.id
        }
      }

      post '/users', params: user_params, headers: headers

      expect(response.status).to eq(422)
    end
  end

  describe 'PATCH /users/:id' do
    it 'updates user successfully' do
      update_params = {
        user: { full_name: 'Updated Name' }
      }

      patch "/users/#{student.id}", params: update_params, headers: headers

      expect(response.status).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response['full_name']).to eq('Updated Name')
    end

    it 'returns 404 for non-existent user' do
      update_params = {
        user: { full_name: 'Does Not Matter' }
      }

      patch '/users/999999', params: update_params, headers: headers

      expect(response.status).to eq(404)
    end
  end

  describe 'DELETE /users/:id' do
    it 'deletes user successfully' do
      user_to_delete = User.create!(
        name: 'user_to_delete',
        password: 'password123',
        role_id: student_role.id,
        full_name: 'To Delete',
        email: 'delete@example.com'
      )

      delete "/users/#{user_to_delete.id}", headers: headers

      expect(response.status).to eq(204)
      expect(User.find_by(id: user_to_delete.id)).to be_nil
    end

    it 'returns 404 for non-existent user' do
      delete '/users/999999', headers: headers

      expect(response.status).to eq(404)
    end
  end
end
