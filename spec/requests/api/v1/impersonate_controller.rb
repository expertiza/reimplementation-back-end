require 'swagger_helper'
require 'rails_helper'

describe 'Impersonate API', type: :request do
  let(:role) { create(:role, id: 1, name: 'Super-Administrator') }
  let(:institution) { create(:institution, id: 100, name: 'NCSU') }
  let(:user) {create(:user, id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: role.id, institution_id: institution.id) }
  let(:user_name) { user.name }
  let(:auth_token) {generate_auth_token(user)}

  path '/api/v1/impersonate' do

    get 'Retrieves a list of users' do
      tags 'Impersonate'
      produces 'application/json'
      parameter name: :user_name, in: :path, type: :string
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'user list retrieved' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['userList']).not_to be_empty
        end
      end
    end
  end

  path '/api/v1/impersonate' do
  
    post 'Impersonates a user' do
      tags 'Impersonate'
      consumes 'application/json'
      parameter name: :impersonate_id, in: :query, type: :integer
  
      response '200', 'successfully impersonated' do
        let(:user) { create(:user) }
        let(:other_user) { create(:user) }
        let(:impersonate_id) { other_user.id }
  
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['token']).not_to be_nil
        end
      end
  
      response '422', 'unprocessable entity' do
        let(:impersonate_id) { '' }
  
        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
  
    end
  end

end
