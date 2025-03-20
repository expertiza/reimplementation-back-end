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

      response '200', 'Returns participants' do
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

      response '200', 'Participant not found with user_id' do
        let(:user_id) { instructor.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)  
          expect(data).to be_empty 
        end
      end

      response '404', 'User Not Found' do
        let(:user_id) { 99 }

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

      response '200', 'Returns participants' do
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

      response '404', 'Assignment Not Found' do
        let(:assignment_id) { 99 }
        # let(:'Authorization') { "Bearer #{@token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Assignment not found')
        end
      end

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

      response '201', 'Returns a participant' do
        let(:id) { participant2.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(studenta.id)
          expect(data['assignment_id']).to eq(assignment2.id)
        end
      end

      response '404', 'Participant not found' do
        let(:id) { 99 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Found')
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

      response '200', 'Participant deleted' do
        let(:id) { participant2.id }

        run_test! do |response|
          expect(JSON.parse(response.body)['message']).to include('Participant')
        end
      end

      response '404', 'Participant not found' do
        let(:id) { 99 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Not Found')
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

  path '/api/v1/participants/{id}/{authorization}' do
    patch 'Update participant authorization' do
      tags 'Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, description: 'ID of the participant'
      parameter name: :authorization, in: :path, type: :string, description: 'New authorization'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '201', 'Participant updated' do
        let(:id) { 2 }
        let(:authorization) { 'mentor' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['authorization']).to eq('mentor')
        end
      end

      response '404', 'Participant not found' do
        let(:id) { 99 }
        let(:authorization) { 'mentor' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Participant not found')
        end
      end

      response '404', 'Participant not found' do
        let(:id) { 99 }
        let(:authorization) { 'teacher' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('Participant not found')
        end
      end

      response '422', 'Authorization not found' do
        let(:id) { 1 }
        let(:authorization) { 'teacher' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
        end
      end

      response '401', 'Unauthorized' do
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

      response '201', 'Participant successfully added' do
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

      response '500', 'Participant already exist' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studenta.id, assignment_id: assignment1.id } }
        let(:name) { User.find(participant[:user_id]).name }

        run_test! do |response|

          expect(JSON.parse(response.body)['exception']).to eq("#<RuntimeError: The user #{name} is already a participant.>")
        end
      end

      response '404', 'User not found' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: 99, assignment_id: 1 } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('User not found')
        end
      end

      response '404', 'Assignment not found' do
        let(:authorization) { 'mentor' }
        let(:participant) { { user_id: studenta.id, assignment_id: 99 } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Assignment not found')
        end
      end

      response '422', 'Authorization not found' do
        let(:authorization) { 'teacher' }
        let(:participant) { { user_id: studentb.id, assignment_id: assignment1.id } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eql('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
        end
      end

      response '422', 'Invalid authorization' do
        let(:authorization) { 'invalid_auth' }
        let(:participant) { { user_id: studentb.id, assignment_id: assignment1.id } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to include('authorization not valid')
        end
      end
    end
  end
end