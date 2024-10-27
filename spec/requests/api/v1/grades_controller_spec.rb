require 'swagger_helper'

RSpec.describe describe 'Grades API', type: :request do
  let(:user) { create(:user) }

  # Chat GPT assisted on before method
  before do
    post '/api/v1/login', params: { email: user.email, password: 'password' }
    @token = JSON.parse(response.body)['token']
  end

  path '/api/v1/grades/{action}/action_allowed' do
    parameter name: 'action', in: :path, type: :string, description: 'the action the user wishes to perform'
    let(:action) { 'view_team' }

    get('action_allowed') do
      tags 'Grades'
      header 'Authorization', "Bearer #{@token}"
      response(200, 'successful') do
        run_test!
      end
    end

  end
end