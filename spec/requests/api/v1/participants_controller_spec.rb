require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Participants API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:studenta) do
    User.create!(
      name: "studenta",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "testuser@example.com"
    )
  end

  let(:studentb) do
    User.create!(
      name: "studentb",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student B",
      email: "testuser@example.com"
    )
  end

  let!(:instructor) do
    User.create!(
      name: "Instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let!(:assignment1) { Assignment.create!(name: 'Test Assignment 1', instructor_id: instructor.id) }
  let!(:assignment2) { Assignment.create!(name: 'Test Assignment 2', instructor_id: instructor.id) }
  let!(:participant1) { Participant.create!(id: 1, user_id: studenta.id, assignment_id: assignment1.id) }
  let!(:participant2) { Participant.create!(id: 2, user_id: studenta.id, assignment_id: assignment2.id) }

  let(:token) { JsonWebToken.encode({id: studenta.id}) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/participants/user/{user_id}' do
    get 'Retrieve participants for a specific user' do
      tags 'Participants'
      produces 'application/json'

      parameter name: :user_id, in: :path, type: :integer, description: 'ID of the user'

      # Test ID 1
      response '200', 'Test ID 1: Returns participants with user ID' do
        let(:user_id) { studenta.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          participant = data[0]
          expect(participant).to be_a(Hash)
          expect(participant['id']).to eq(participant1.id) 
          expect(participant['user_id']).to eq(studenta.id)
          expect(participant['assignment_id']).to eq(assignment1.id)
        end
      end

      # Test ID 2
      response '200', 'Test ID 2: Participant not found with user_id' do
        let(:user_id) { instructor.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)  
          expect(data).to be_empty 
        end
      end

      # Test ID 3
      response '404', 'Test ID 3: Get participants with invalid user' do
        let(:user_id) { 99 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('User not found')
        end
      end

      # Test ID 4
      response '401', 'Test ID 4: Get participant with user ID with invalid token' do
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

      # Test ID 5
      response '200', 'Test ID 5: Returns participants with assignment ID' do
        let(:assignment_id) { assignment1.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          participant = data[0]
          expect(participant).to be_a(Hash)
          expect(participant['id']).to eq(participant1.id)
          expect(participant['user_id']).to eq(studenta.id)
          expect(participant['assignment_id']).to eq(assignment1.id)
        end
      end

      # Test ID 6
      response '404', 'Test ID 6: Get participant with invalid assignment' do
        let(:assignment_id) { 99 }
        # let(:'Authorization') { "Bearer #{@token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Assignment not found')
        end
      end

      # Test ID 7
      response '401', 'Test ID 7: Get participant with assignment ID with invalid token' do
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

      # Test ID 8
      response '200', 'Test ID 8: Gets participant with participant ID' do
        let(:id) { participant2.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(studenta.id)
          expect(data['assignment_id']).to eq(assignment2.id)
        end
      end

      # Test ID 9
      response '404', 'Test ID 9: Get participant with invalid id' do
        let(:id) { 99 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Found')
        end
      end

      # Test ID 10
      response '401', 'Test ID 10: Get participant with invalid token' do
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

      # Test ID 11
      response '200', 'Test ID 11: Delete participant' do
        let(:id) { participant2.id }

        run_test! do |response|
          expect(JSON.parse(response.body)['message']).to include('Participant')
        end
      end

      # Test ID 12
      response '404', 'Test ID 12: Delete participant with invalid particiant ID' do
        let(:id) { 99 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Found')
        end
      end

      # Test ID 13
      response '401', 'Test ID 13: Delete participant with invalid token' do
        let(:id) { 2 }
        let(:'Authorization') { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
        end
      end
    end
  end

  path '/api/v1/participants/{id}/{authorization}' do
    patch 'Update participant authorization' do
      tags 'Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, description: 'ID of the participant'
      parameter name: :authorization, in: :path, type: :string, description: 'New authorization'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      # Test ID 14
      response '201', 'Test ID 14: Update participant' do
        let(:id) { 2 }
        let(:authorization) { 'mentor' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['authorization']).to eq('mentor')
        end
      end

      # Test ID 15
      response '404', 'Test ID 15: Update participant with invalid participant ID' do
        let(:id) { 99 }
        let(:authorization) { 'mentor' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Participant not found')
        end
      end

      # Test ID 16
      response '422', 'Test ID 16: Update participant with invalid role' do
        let(:id) { 1 }
        let(:authorization) { 'teacher' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
        end
      end

      # Test ID 17
      response '401', 'Test ID 17: Update participant with invalid token' do
        let(:id) { 2 }
        let(:authorization) { 'mentor' }
        let(:'Authorization') { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Authorized')
        end
      end
    end
  end

  path '/api/v1/participants/{authorization}' do
    post 'Add a participant' do
      tags 'Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :authorization, in: :path, type: :string, description: 'Authorization level (Reader, Reviewer, Submitter, Mentor)'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
      parameter name: :participant, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer, description: 'ID of the user' },
          assignment_id: { type: :integer, description: 'ID of the assignment' }
        },
        required: %w[user_id assignment_id]
      }

      # Test ID 18
      response '201', 'Test ID 18: Participant successfully added' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studentb.id, assignment_id: assignment2.id } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(studentb.id)
          expect(data['assignment_id']).to eq(assignment2.id)
          expect(data['authorization']).to eq('mentor')
        end
      end

      def fetch_username(user_id)
        User.find(user_id).name
      end

      # Test ID 19
      response '500', 'Test ID 19: Add participant that already exist' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studenta.id, assignment_id: assignment1.id } }
        let(:name) { User.find(participant[:user_id]).name }

        run_test! do |response|

          expect(JSON.parse(response.body)['exception']).to eq("#<RuntimeError: The user #{name} is already a participant.>")
        end
      end

      # Test ID 20
      response '404', 'Test ID 20: Add participant with invalid user ID' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: 99, assignment_id: 1 } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('User not found')
        end
      end

      # Test ID 21
      response '404', 'Test ID 21: Add participant with invalid assignment ID' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studenta.id, assignment_id: 99 } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Assignment not found')
        end
      end

      # Test ID 22
      response '422', 'Test ID 22: Add participant with invalid authorization' do
        let(:authorization) { 'teacher' }
        let(:participant) { { user_id: studentb.id, assignment_id: assignment1.id } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
        end
      end

      # Test ID 23
      response '422', 'Test ID 23: Add participant with invalid authorization format' do
        let(:authorization) { 'invalid_auth' }
        let(:participant) { { user_id: studentb.id, assignment_id: assignment1.id } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to include('authorization not valid')
        end
      end

      # Test ID 24
      response '404', 'Test ID 24: Missing user_id in request body' do
        let(:authorization) { 'mentor' }
        let(:participant) { { assignment_id: assignment1.id } }

        run_test! do |response|
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['error']).to eq('User not found')
        end
      end

      # Test ID 25
      response '404', 'Test ID 25: Missing assignment_id in request body' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studentb.id } }

        run_test! do |response|
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['error']).to eq('Assignment not found')
        end
      end
      
    end
  end
end