require 'swagger_helper'
require 'json_web_token'

RSpec.describe AuthenticationController, type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: "Test Institution")
  end

  path '/login' do
    post 'Logs in a user' do
      tags 'Authentication'
      consumes 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          user_name: { type: :string },
          password: { type: :string }
        },
        required: %w[user_name password]
      }

      response '200', 'successful login' do
        schema type: :object,
               properties: { token: { type: :string } },
               required: ['token']
        let(:user) do
          User.create!(
            name: "studenta",
            password: "password",
            role_id: @roles[:student].id,
            full_name: "Student A",
            email: "testuser@example.com",
            institution: @institution
          )
        end
        let(:credentials) { { user_name: user.name, password: 'password' } }

        let(:token) { JsonWebToken.encode({id: user.id}) }
        let(:Authorization) { "Bearer #{token}" }
        let(:headers) { { "Authorization" => "Bearer #{token}" } }
        run_test! do |response|
          json_response = JSON.parse(response.body)
          token = json_response['token']
          expect(token).to be_present

          decoded_token = JsonWebToken.decode(token)

          expect(decoded_token['id']).to eq(user.id)
          expect(decoded_token['name']).to eq(user.name)
          expect(decoded_token['full_name']).to eq(user.full_name)
          expect(decoded_token['role']).to eq(user.role.name)
          expect(decoded_token['institution_id']).to eq(user.institution.id)
        end
      end

      response '401', 'invalid credentials' do
        schema type: :object,
               properties: { error: { type: :string } },
               required: ['error']
        let(:user) do
          User.create!(
            name: "studenta",
            password: "password",
            role_id: @roles[:student].id,
            full_name: "Student A",
            email: "testuser@example.com",
            institution: @institution
          )
        end
        let(:credentials) { { user_name: user.name, password: 'wrongpassword' } }
        let(:token) { JsonWebToken.encode({id: user.id}) }
        let(:Authorization) { "Bearer #{token}" }
        let(:headers) { { "Authorization" => "Bearer #{token}" } }
        run_test!
      end
    end
  end
end
