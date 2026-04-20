# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Users API', type: :request do
  before(:each) do
    @roles = create_roles_hierarchy
  end

  let!(:user) do
    User.create!(
      name: 'testuser',
      password: 'password',
      password_confirmation: 'password',
      role_id: @roles[:student].id,
      full_name: 'Test User',
      email: 'testuser@example.com'
    )
  end

  let(:token) { JsonWebToken.encode({ id: user.id }) }
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
          expect(data.map { |u| u['id'] }).to include(user.id)
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
        let(:id) { user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(user.id)
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
end
