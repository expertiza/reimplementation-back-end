require 'swagger_helper'

RSpec.describe AuthenticationController, type: :request do
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
        let(:user) { create(:user, name: 'testuser', full_name: 'Test User') }
        let(:credentials) { { user_name: user.name, password: 'password' } }
        run_test!

        it 'returns a JWT token' do
          token = JSON.parse(response.body)['token']
          decoded_token = JsonWebToken.decode(token)

          expect(decoded_token['id']).to eq(user.id)
          expect(decoded_token['name']).to eq(user.name)
          expect(decoded_token['full_name']).to eq(user.full_name)
          expect(decoded_token['role']).to eq(user.role.name)
          expect(decoded_token['institution_id']).to eq(user.institution.id)
        end
      end

      response '401', 'invalid credentials' do
        let(:user) { create(:user, name: 'testuser') }
        let(:credentials) { { user_name: user.name, password: 'wrongpassword' } }
        run_test!
      end
    end
  end
end
