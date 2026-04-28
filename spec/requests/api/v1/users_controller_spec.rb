# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Users API', type: :request do
  before(:each) do
    @roles = create_roles_hierarchy
  end

  let!(:auth_user) do
    User.create!(
      name: 'testuser',
      password: 'password',
      password_confirmation: 'password',
      role_id: @roles[:student].id,
      full_name: 'Test User',
      email: 'testuser@example.com'
    )
  end

  let(:token) { JsonWebToken.encode({ id: auth_user.id }) }
  let(:Authorization) { "Bearer #{token}" }

  path '/users' do
    get 'List all users' do
      tags 'Users'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true

      response '200', 'Returns user list' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.map { |u| u['id'] }).to include(auth_user.id)
        end
      end
      # Scenario: invalid token should be rejected before hitting controller action
      response '401', 'Unauthorized when token is invalid' do
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/users/{id}' do
    get 'Get a user by id' do
      tags 'Users'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer
      parameter name: 'Authorization', in: :header, type: :string, required: true

      response '200', 'Returns the user' do
        let(:id) { auth_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(auth_user.id)
          expect(data.keys).to include('id', 'email')
        end
      end

      response '404', 'User not found' do
        let(:id) { 0 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to include('not found')
        end
      end
    end
  end
  path '/users' do
    post 'Create a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              name: { type: :string },
              role_id: { type: :integer },
              full_name: { type: :string },
              email: { type: :string },
              parent_id: { type: :integer },
              institution_id: { type: :integer },
              password: { type: :string },
              password_confirmation: { type: :string }
            },
            required: %w[name role_id full_name email password password_confirmation]
          }
        },
        required: ['user']
      }

      # Scenario: valid payload creates user
      response '201', 'Creates a user with valid payload' do
        let(:payload) do
          {
            user: {
              name: 'newstudentuser',
              role_id: @roles[:student].id,
              full_name: 'New Student User',
              email: 'newstudentuser@example.com',
              password: 'password',
              password_confirmation: 'password'
            }
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['username']).to eq('newstudentuser')
          expect(body['email']).to eq('newstudentuser@example.com')
        end
      end

      # Scenario: invalid payload returns validation errors
      response '422', 'Rejects invalid payload' do
        let(:payload) do
          {
            user: {
              name: 'bademailuser',
              role_id: @roles[:student].id,
              full_name: 'Bad Email User',
              email: 'invalid_email',
              password: 'password',
              password_confirmation: 'password'
            }
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key('email')
        end
      end
      # Scenario: duplicate username should fail uniqueness validation
      response '422', 'Rejects duplicate username' do
        let!(:existing_user) do
          User.create!(
            name: 'duplicateuser',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Duplicate User One',
            email: 'duplicateuser1@example.com'
          )
        end

        let(:payload) do
          {
            user: {
              name: 'duplicateuser',
              role_id: @roles[:student].id,
              full_name: 'Duplicate User Two',
              email: 'duplicateuser2@example.com',
              password: 'password',
              password_confirmation: 'password'
            }
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key('name')
        end
      end
      # Scenario: password confirmation mismatch should be rejected
      response '422', 'Rejects mismatched password confirmation' do
        let(:payload) do
          {
            user: {
              name: 'pw_mismatch_user',
              role_id: @roles[:student].id,
              full_name: 'Password Mismatch User',
              email: 'pw_mismatch_user@example.com',
              password: 'password',
              password_confirmation: 'different_password'
            }
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key('password_confirmation')
        end
      end

      # Scenario: missing user param triggers ParameterMissing handler
      response '422', 'Rejects request when user param is missing' do
        let(:payload) { {} }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Parameter missing')
        end
      end
    end
  end

  path '/users/{id}' do
    parameter name: :id, in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true

    put 'Update a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              full_name: { type: :string },
              email: { type: :string }
            }
          }
        },
        required: ['user']
      }


      # Scenario: valid update returns 200
      response '200', 'Updates user with valid payload' do
        let(:id) { auth_user.id }
        let(:payload) { { user: { full_name: 'Updated Full Name' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['fullName']).to eq('Updated Full Name')
        end
      end

      # Scenario: invalid update returns 422
      response '422', 'Rejects invalid update payload' do
        let(:id) { auth_user.id }
        let(:payload) { { user: { email: 'not_an_email' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key('email')
        end
      end

      # Scenario: missing user param should trigger ParameterMissing handler
      response '422', 'Rejects update when user param is missing' do
        let(:id) { auth_user.id }
        let(:payload) { {} }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Parameter missing')
        end
      end

      # Scenario: missing id returns 404
      response '404', 'Returns not found for missing user id' do
        let(:id) { 0 }
        let(:payload) { { user: { full_name: 'No User' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to include('not found')
        end
      end
    end

    patch 'Partially update a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              full_name: { type: :string },
              email: { type: :string }
            }
          }
        },
        required: ['user']
      }

      # Scenario: valid partial update returns 200
      response '200', 'Partially updates user with valid payload' do
        let(:id) { auth_user.id }
        let(:payload) { { user: { full_name: 'Patched Full Name' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['fullName']).to eq('Patched Full Name')
        end
      end

      # Scenario: invalid partial update returns 422
      response '422', 'Rejects invalid partial update payload' do
        let(:id) { auth_user.id }
        let(:payload) { { user: { email: 'still_invalid_email' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to have_key('email')
        end
      end
      # Scenario: missing user param should trigger ParameterMissing handler on patch
      response '422', 'Rejects partial update when user param is missing' do
        let(:id) { auth_user.id }
        let(:payload) { {} }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Parameter missing')
        end
      end

      # Scenario: missing id returns 404
      response '404', 'Returns not found for missing user id on patch' do
        let(:id) { 0 }
        let(:payload) { { user: { full_name: 'No Patch User' } } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to include('not found')
        end
      end
    end

    delete 'Delete a user' do
      tags 'Users'
      produces 'application/json'

      # Scenario: existing id delete path
      response '204', 'Deletes existing user' do
        let!(:deletable_user) do
          User.create!(
            name: 'deletableuser',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Deletable User',
            email: 'deletableuser@example.com'
          )
        end
        let(:id) { deletable_user.id }

        run_test! do |_response|
          expect(User.exists?(id)).to eq(false)
        end
      end

      # Scenario: missing id returns 404
      response '404', 'Returns not found when deleting missing user' do
        let(:id) { 0 }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to include('not found')
        end
      end
    end
  end

  path '/users/institution/{id}' do
    parameter name: :id, in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true

    get 'Get users by institution' do
      tags 'Users'
      produces 'application/json'

      let!(:institution_a) { Institution.create!(name: 'Institution A') }
      let!(:institution_b) { Institution.create!(name: 'Institution B') }

      let!(:inst_user_1) do
        User.create!(
          name: 'instuserone',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:student].id,
          full_name: 'Institution User One',
          email: 'instuserone@example.com',
          institution_id: institution_a.id
        )
      end

      let!(:inst_user_2) do
        User.create!(
          name: 'instusertwo',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:ta].id,
          full_name: 'Institution User Two',
          email: 'instusertwo@example.com',
          institution_id: institution_a.id
        )
      end

      let!(:other_inst_user) do
        User.create!(
          name: 'otherinstuser',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:student].id,
          full_name: 'Other Institution User',
          email: 'otherinstuser@example.com',
          institution_id: institution_b.id
        )
      end

      # Scenario: valid institution id returns users for that institution
      response '200', 'Returns institution-scoped users' do
        let(:id) { institution_a.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          ids = data.map { |u| u['id'] }
          expect(ids).to include(inst_user_1.id, inst_user_2.id)
          expect(ids).not_to include(other_inst_user.id)
        end
      end

      # Scenario: missing institution id returns 404
      response '404', 'Returns not found for missing institution' do
        let(:id) { 0 }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to include("Couldn't find Institution")
        end
      end
    end
  end

  path '/users/{id}/managed' do
    parameter name: :id, in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true

    get 'Get managed users' do
      tags 'Users'
      produces 'application/json'

      # Scenario: student parent cannot manage users
      response '422', 'Returns error for student parent' do
        let!(:student_parent) do
          User.create!(
            name: 'studentparent',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Parent',
            email: 'studentparent@example.com'
          )
        end
        let(:id) { student_parent.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Students do not manage any users')
        end
      end

      # Scenario: instructor parent returns managed users
      response '200', 'Returns managed users for instructor parent' do
        let!(:instructor_parent) do
          User.create!(
            name: 'instructorparent',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:instructor].id,
            full_name: 'Instructor Parent',
            email: 'instructorparent@example.com'
          )
        end

        let!(:managed_user) do
          User.create!(
            name: 'managedchild',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Managed Child',
            email: 'managedchild@example.com',
            parent_id: instructor_parent.id
          )
        end

        let!(:unmanaged_user) do
          User.create!(
            name: 'unmanagedchild',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Unmanaged Child',
            email: 'unmanagedchild@example.com'
          )
        end

        let(:id) { instructor_parent.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          ids = data.map { |u| u['id'] }
          expect(ids).to include(managed_user.id)
          expect(ids).not_to include(unmanaged_user.id)
        end
      end
            # Scenario: administrator should manage users from same institution except self
      response '200', 'Returns institution users for administrator parent' do
        let!(:institution_admin) { Institution.create!(name: 'Admin Institution') }
        let!(:other_institution) { Institution.create!(name: 'Other Institution') }

        let!(:admin_parent) do
          User.create!(
            name: 'adminparent',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:admin].id,
            full_name: 'Administrator Parent',
            email: 'adminparent@example.com',
            institution_id: institution_admin.id
          )
        end

        let!(:same_institution_user) do
          User.create!(
            name: 'sameinstuser',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Same Institution User',
            email: 'sameinstuser@example.com',
            institution_id: institution_admin.id
          )
        end

        let!(:other_institution_user) do
          User.create!(
            name: 'otherinstmanaged',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other Institution User',
            email: 'otherinstmanaged@example.com',
            institution_id: other_institution.id
          )
        end

        let(:id) { admin_parent.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          ids = data.map { |u| u['id'] }
          expect(ids).to include(same_institution_user.id)
          expect(ids).not_to include(admin_parent.id)
          expect(ids).not_to include(other_institution_user.id)
        end
      end

      # Scenario: super administrator should manage all users
      response '200', 'Returns all users for super administrator parent' do
        let!(:super_admin_parent) do
          User.create!(
            name: 'superadminparent',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:super_admin].id,
            full_name: 'Super Administrator Parent',
            email: 'superadminparent@example.com'
          )
        end

        let!(:another_user) do
          User.create!(
            name: 'anothermanageduser',
            password: 'password',
            password_confirmation: 'password',
            role_id: @roles[:student].id,
            full_name: 'Another Managed User',
            email: 'anothermanageduser@example.com'
          )
        end

        let(:id) { super_admin_parent.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          ids = data.map { |u| u['id'] }
          expect(ids).to include(super_admin_parent.id, another_user.id, auth_user.id)
        end
      end
    end
  end

  path '/users/role/{name}' do
    parameter name: :name, in: :path, type: :string
    parameter name: 'Authorization', in: :header, type: :string, required: true

    get 'Get users by role name' do
      tags 'Users'
      produces 'application/json'

      let!(:ta_user_1) do
        User.create!(
          name: 'tauserone',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:ta].id,
          full_name: 'TA User One',
          email: 'tauserone@example.com'
        )
      end

      let!(:ta_user_2) do
        User.create!(
          name: 'tausertwo',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:ta].id,
          full_name: 'TA User Two',
          email: 'tausertwo@example.com'
        )
      end

      let!(:student_user_for_filter) do
        User.create!(
          name: 'studentforfilter',
          password: 'password',
          password_confirmation: 'password',
          role_id: @roles[:student].id,
          full_name: 'Student For Filter',
          email: 'studentforfilter@example.com'
        )
      end

      # Scenario: valid role name returns role-scoped users
      response '200', 'Returns users for a valid role name' do
        let(:name) { 'teaching_assistant' }

        run_test! do |response|
          data = JSON.parse(response.body)
          ids = data.map { |u| u['id'] }
          expect(ids).to include(ta_user_1.id, ta_user_2.id)
          expect(ids).not_to include(student_user_for_filter.id)
        end
      end

      # Scenario: invalid token should return 401 for role-based listing
      response '401', 'Unauthorized when token is invalid' do
        let(:name) { 'student' }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq('Not Authorized')
        end
      end

      # Scenario: invalid role name returns 404 from controller
      response '404', 'Returns not found for invalid role name' do
        let(:name) { 'role_that_does_not_exist' }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body['error']).to eq("Role 'Role That Does Not Exist' not found")
        end
      end
    end
  end
end
