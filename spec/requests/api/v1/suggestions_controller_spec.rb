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
    @current_user = @user
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

      response '201', 'comment_added' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { { comment: 'This is a test comment' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['comment']).to eq('This is a test comment')
          expect(response.status).to eq(201)
        end
      end

      response '422', 'unprocessable entity for missing or empty comment' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { '' }

        before do
          # Mock the params to simulate the request
          allow_any_instance_of(ActionController::Parameters).to receive(:require).with(:id).and_return(id)
          allow_any_instance_of(ActionController::Parameters).to receive(:require).with(:comment).and_return(comment)
          # Mock params[:id] and params[:comment] in the controller context
          allow_any_instance_of(ActionController::Parameters).to receive(:[]).with(:id).and_return(id)
          allow_any_instance_of(ActionController::Parameters).to receive(:[]).with(:comment).and_return(comment)
        end

        run_test! do |response|
          expect(response.status).to eq(422) # Expect 400 if the comment is missing or empty
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

  path '/api/v1/suggestions/{id}/approve' do
    post 'Approve suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'
      context '| when user is instructor | ' do
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end
        response '200', 'suggestion approved' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('Approved')
          end
        end

        response '422', 'unprocessable entity' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          before do
            # Simulating an error in the approval process (e.g., ActiveRecord::RecordInvalid)
            allow_any_instance_of(Suggestion).to receive(:update_attribute).and_raise(ActiveRecord::RecordInvalid)
          end

          run_test! do |response|
            expect(response.status).to eq(422)
          end
        end

        response '404', 'suggestion not found' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { -1 }

          run_test! do |response|
            expect(response.status).to eq(404)
          end
        end
      end
      context ' | when user is student | ' do
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end
        response '403', 'students cannot approve suggestions' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(403)
            expect(JSON.parse(response.body)['error']).to eq('Students cannot approve a suggestion.')
          end
        end
      end
    end
  end

  path '/api/v1/suggestions' do
    post 'Create a new suggestion' do
      tags 'Suggestions'
      consumes 'application/json'

      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :title, in: :body, type: :string, required: true
      parameter name: :description, in: :body, type: :string, required: true
      parameter name: :assignment_id, in: :body, type: :integer, required: true
      parameter name: :auto_signup, in: :body, type: :boolean, required: true
      parameter name: :anonymous, in: :body, type: :boolean, required: true

      context 'when user is authorized' do
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end

        response '201', 'suggestion created successfully' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:title) { 'Sample suggestion' }
          let(:description) { 'This is a sample suggestion.' }
          let(:assignment_id) { assignment.id }
          let(:auto_signup) { true }
          let(:anonymous) { false }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(response.status).to eq(201)
            expect(data['title']).to eq('Sample suggestion')
            expect(data['description']).to eq('This is a sample suggestion.')
            expect(data['status']).to eq('Initialized')
            expect(data['id']).not_to be_nil
          end
        end

        response '422', 'unprocessable entity' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:title) { nil } # Invalid title (required)
          let(:description) { 'Description without title' }
          let(:assignment_id) { assignment.id }
          let(:auto_signup) { true }
          let(:anonymous) { false }

          run_test! do |response|
            expect(response.status).to eq(422)
            expect(JSON.parse(response.body)['title']).to include("can't be blank")
          end
        end
      end

      context 'when user is unauthorized' do
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end

        response '401', 'unauthorized request' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:title) { 'Sample suggestion' }
          let(:description) { 'This is a sample suggestion.' }
          let(:assignment_id) { assignment.id }
          let(:auto_signup) { true }
          let(:anonymous) { false }

          run_test! do |response|
            expect(response.status).to eq(401)
            expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
          end
        end
      end
    end
  end
end
