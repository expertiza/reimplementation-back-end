require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Participants API', type: :request do
  before(:all) do
      # Log in and retrieve the token once before all tests
      post '/login', params: { user_name: 'admin2@example.com', password: 'password123' }
      expect(response.status).to eq(200)
      @token = JSON.parse(response.body)['token']
    end
  
    let(:valid_headers) { { 'Authorization' => "Bearer #{@token}" } }
  
    
    path '/api/v1/participants/user/{user_id}' do
      get 'Retrieve participants for a specific user' do
        tags 'Participants'
        produces 'application/json'
  
        parameter name: :user_id, in: :path, type: :integer, description: 'ID of the user'
        parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
  
        # Checks if class returns a participant with given user_id if they exist
        response '200', 'Returns participants' do
          let(:user_id) { 4 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            data = JSON.parse(response.body)
            participant = data[0]
            expect(participant).to be_a(Hash)
            expect(participant['id']).to eq(1) 
            expect(participant['user_id']).to eq(4)
            expect(participant['assignment_id']).to eq(1)
          end
        end
  
        # Checks that a 404 Not Found Error is given if participant with user_id is not found
        response '404', 'User Not Found' do
          let(:user_id) { 99 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('User not found')
          end
        end
  
        response '401', 'Unauthorized' do
          let(:user_id) { 1 }
          let(:'Authorization') { 'Bearer invalid_token' }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
          end
        end
      end
    end



    path '/api/v1/participants/assignment/{assignment_id}' do
      get 'Retrieve participants for a specific assignment' do
        tags 'Participants'
        produces 'application/json'
  
        parameter name: :assignment_id, in: :path, type: :integer, description: 'ID of the assignment'
        parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
  
        response '200', 'Returns participants' do
          let(:assignment_id) { 2 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            data = JSON.parse(response.body)
            participant = data[0]
            expect(participant).to be_a(Hash)
            expect(participant['id']).to eq(2) 
            expect(participant['user_id']).to eq(5)
            expect(participant['assignment_id']).to eq(2)
          end
        end
  
        # Checks that a 404 Not Found Error is given if participant with assignment_id is not found
        response '404', 'Assignment Not Found' do
          let(:assignment_id) { 99 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Assignment not found')
          end
        end
  
        # Checks if endpoint checks for bearer token authorization
        response '401', 'Unauthorized' do
          let(:assignment_id) { 2 }
          let(:'Authorization') { 'Bearer invalid_token' }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
          end
        end
      end
    end

    path '/api/v1/participants/{id}' do
      get 'Retrieve a specific participant' do
        tags 'Participants'
        produces 'application/json'
  
        parameter name: :id, in: :path, type: :integer, description: 'ID of the participant'
        parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
  
        response '200', 'Returns a participant' do
          let(:id) { 2 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['user_id']).to eq(5)
            expect(data['assignment_id']).to eq(2)
          end
        end
  
        
        response '404', 'Participant not found' do
          let(:id) { 99 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Participant Not Found')
          end
        end
  
        response '401', 'Unauthorized' do
          let(:id) { 2 }
          let(:'Authorization') { 'Bearer invalid_token' }
    
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
          end
        end
      end
  
      
      delete 'Delete a specific participant' do
        tags 'Participants'
        parameter name: :id, in: :path, type: :integer, description: 'ID of the participant'
        parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
  
        # Test deleting a participant
        response '204', 'Participant deleted' do
          let(:id) { 2 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            #expect(JSON.parse(response.body)['message']).to eql('')
            expect(response.body).to be_empty
          end
        end
  
        
        response '404', 'Participant not found' do
          let(:id) { 99 }
          let(:'Authorization') { "Bearer #{@token}" }
  
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Participant Not Found')
          end
        end
  
        response '401', 'Unauthorized' do
          let(:id) { 2 }
          let(:'Authorization') { 'Bearer invalid_token' }
    
          run_test! do |response|
            expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
          end
        end
      end
    end

  end

