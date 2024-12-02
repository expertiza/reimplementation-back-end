require 'swagger_helper'

RSpec.describe 'Participants API', type: :request do
  path '/api/v1/participants/user/{user_id}' do
    get 'Filter participants by user' do
      tags 'Participants'
      produces 'application/json'
      parameter name: :user_id, in: :path, type: :integer, description: 'User ID', required: true

      response '200', 'Participants found' do
        let(:user) { create(:user) }
        let(:user_id) { user.id } 
        let!(:participant) { create(:participant, user_id: user.id) }
        run_test!
      end

      response '404', 'User not found' do
        let(:user_id) { 0 } # Nonexistent user ID
        run_test!
      end
    end
  end
    
  path '/api/v1/participants/assignment/{assignment_id}' do
    get 'Filter participants by assignment' do
      tags 'Participants'
      produces 'application/json'
      parameter name: :assignment_id, in: :path, type: :integer, description: 'Assignment ID', required: true

      response '200', 'Participants found' do
        let(:assignment) { create(:assignment) } # Assuming FactoryBot
        let(:assignment_id) { assignment.id }    # Use the created assignment's ID
        let!(:participant) { create(:participant, assignment_id: assignment.id) }  
        run_test!
      end

      response '404', 'Assignment not found' do
        let(:assignment_id) { 0 } # Nonexistent assignment ID
        run_test!
      end
    end
  end

  path '/api/v1/participants/{id}' do
    get 'Retrieve a participant' do
      tags 'Participants'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, description: 'Participant ID', required: true

      response '200', 'Participant found' do
        let(:participant) { create(:participant) }
        let(:id) { participant.id }

        run_test!
      end
      response '404', 'Participant not found' do
        let(:participant_id) { 0 } # Nonexistent assignment ID
        run_test!
      end
    end
  end
        

  path '/api/v1/participants/{designation}' do
    post('add participant') do
      tags 'Participants'
      consumes 'application/json'
      parameter name: :designation, in: :path, type: :string, description: 'designation of the participant'
      parameter name: :participant, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer },
          assignment_id: { type: :integer },
          team_id: { type: :integer, nullable: true },
        },
        required: ['user_id', 'assignment_id'] # Add designation to required fields
      }
  
      response(201, 'participant created') do
        let(:user) { User.create(email: 'test@example.com', password: 'password') }
        let(:assignment) { Assignment.create(title: 'Test Assignment') }
        let(:designation) { 'student' }
        let(:participant) { { user_id: user.id, assignment_id: assignment.id } }
  
        run_test!
      end
  
      response(422, 'invalid request') do
        let(:designation) { 'invalid_designation' }
        let(:participant) { { user_id: nil, assignment_id: nil } }
        run_test!
      end
    end
  end

  path '/api/v1/participants/{id}/{designation}' do
    patch('update participant designation') do
      tags 'Participants'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :integer, description: 'Participant ID'
      parameter name: :designation, in: :path, type: :string, description: 'New designation for the participant'
  
      response(201, 'participant designation updated') do
        let(:user) { User.create(email: 'test@example.com', password: 'password') }
        let(:assignment) { Assignment.create(title: 'Test Assignment') }
        let(:participant) { AssignmentParticipant.create(user_id: user.id, assignment_id: assignment.id, designation: 'student') }
        let(:id) { participant.id }
        let(:designation) { 'mentor' }
  
        run_test!
      end
  
      response(422, 'invalid request') do
        let(:id) { 0 }
        let(:designation) { 'invalid_designation' }
        run_test!
      end
    end
  end

  path '/api/v1/participants/{id}' do
  delete('Delete participant') do
    tags 'Participants'
    parameter name: :id, in: :path, type: :integer, description: 'Participant ID', required: true

      response '200', 'Participant deleted successfully' do
        let(:participant) { create(:participant) }
        let(:id) { participant.id }            
        run_test!
      end

      response '404', 'Participant not found' do
        let(:id) { 0 } 
        run_test!
      end
    end
  end

end