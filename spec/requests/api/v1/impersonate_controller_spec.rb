require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Impersonate API', type: :request do
  let(:role) { create(:role, id: 1, name: 'Super-Administrator') }
  let(:institution) { create(:institution, id: 100, name: 'NCSU') }
  let(:user) {create(:user, id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: role.id, institution_id: institution.id) }
  let(:user_name) { user.name }


  path '/api/v1/impersonate' do

    get('list of impersonatable users') do
      tags 'Impersonate'
      produces 'application/json'
      parameter name: :user_name, in: :path, type: :string

      response('200', 'user list retrieved') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post 'Impersonates a user' do
      tags 'Impersonate'
      consumes 'application/json'
      parameter name: :impersonate_id, in: :query, type: :string

      response('200', 'successfully impersonated') do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['token']).not_to be_nil
        end
      end

      response '422', 'unprocessable entity' do
        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
  
    end
  end

end
