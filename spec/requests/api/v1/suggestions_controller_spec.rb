require 'swagger_helper'
require 'rails_helper'

def login_user
  # Create a user using the factory
  user = create(:user)

  # Make a POST request to login
  post '/login', params: { user_name: user.name, password: 'password' }

  # Parse the JSON response and extract the token
  json_response = JSON.parse(response.body)

  # Return the token from the response
  { token: json_response['token'], user: }
end

RSpec.describe 'Suggestions API', type: :request do
  before(:each) do
    auth_data = login_user
    @token = auth_data[:token]
    @user = auth_data[:user]
  end

  let(:assignment) { create(:assignment) }
  let(:suggestion) { create(:suggestion, assignment_id: assignment.id, user_id: @user.id) }

  path '/api/v1/suggestions/{id}/add_comment' do
    post 'Add a comment to a suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        },
        required: ['comment']
      }

      response '200', 'comment_added', tag: 'add_comment' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { { comment: 'This is a test comment' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['comment']).to eq('This is a test comment')
        end
      end

      response '422', 'unprocessable entity' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { { comment: '' } }

        run_test! do |response|
          expect(response.status).to eq(422)
        end
      end

      response '404', 'suggestion not found' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { -1 }
        let(:comment) { { comment: 'Invalid ID' } }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
