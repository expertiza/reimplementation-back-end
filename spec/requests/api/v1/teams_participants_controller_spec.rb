require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:institution) { Institution.create!(name: "NC State") }

  let(:instructor_role) { Role.find_or_create_by!(name: "Instructor") }
  let(:ta_role) { Role.find_or_create_by!(name: "Teaching Assistant", parent_id: instructor_role.id) }
  let(:student_role) { Role.find_or_create_by!(name: "Student", parent_id: ta_role.id) }

  let(:instructor) do
    User.create!(
      name: "profa",
      password_digest: "password",
      role_id: instructor_role.id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      institution_id: institution.id
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: "Sample Assignment",
      instructor_id: instructor.id
    )
  end

  let(:team) do
    Team.create!(
      assignment_id: assignment.id
    )
  end

  let(:participant) do
    User.create!(
      full_name: "Test Participant",
      name: "Test",
      email: "participant@example.com",
      password_digest: "password",
      role_id: student_role.id
    )
  end

  let(:team_participant) do
    TeamParticipant.create!(
      user_id: participant.id,
      team_id: team.id
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  ### ✅ **Update Duties Test**
  path '/api/v1/teams_participants/update_duties' do
    put('update participant duties') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          team_participant_id: { type: :integer },
          team_participant: {
            type: :object,
            properties: {
              duty_id: { type: :integer }
            },
            required: ['duty_id']
          }
        },
        required: ['team_participant_id', 'team_participant']
      }

      response(200, 'duty updated successfully') do
        let(:new_user) do
          User.create!(
            full_name: "User One",
            name: "User1",
            email: "user1@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let(:team_participant) { TeamParticipant.create!(team_id: team.id, user_id: new_user.id) }

        let(:payload) do
          {
            team_participant_id: team_participant.id,
            team_participant: { duty_id: 2 }
          }
        end

        run_test!
      end

      response(404, 'team participant not found') do
        let(:payload) do
          {
            team_participant_id: 99999,  # Non-existing ID
            team_participant: { duty_id: 2 }
          }
        end

        run_test! do |response|
          expect(response.body).to include("Couldn't find TeamParticipant")
        end
      end
    end
  end

  ### ✅ **List Participants Test**
  path '/api/v1/teams_participants/list_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'

    get('list participants') do
      tags 'Teams Participants'
      produces 'application/json'

      response(200, 'successful') do
        let(:id) { team.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team_participants']).to be_an(Array)
        end
      end

      response(404, 'team not found') do
        let(:id) { 99999 } # Non-existing team ID

        run_test! do |response|
          expect(response.body).to include("Couldn't find Team")
        end
      end
    end
  end

  ### ✅ **Add Participant Test**
  path '/api/v1/teams_participants/add_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'

    post('add participant') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: { name: { type: :string } },
            required: ['name']
          }
        },
        required: ['user']
      }

      response(302, 'participant added successfully') do
        let(:payload) { { user: { name: participant.name } } }
        let(:id) { team.id }

        run_test!
      end

      response(404, 'participant not found') do
        let(:payload) { { user: { name: 'Invalid User' } } }
        let(:id) { team.id }

        run_test! do |response|
          expect(response.body).to include("Couldn't find User")
        end
      end
    end
  end

  ### ✅ **Delete Participant Test**
  path '/api/v1/teams_participants/delete_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'TeamParticipant ID'

    delete('delete participant') do
      tags 'Teams Participants'
      produces 'application/json'

      response(200, 'participant deleted successfully') do
        let(:id) { team_participant.id }

        run_test! do |response|
          expect(TeamParticipant.exists?(team_participant.id)).to be_falsey
        end
      end

      response(404, 'not found') do
        let(:id) { 0 }

        run_test! do |response|
          expect(response.body).to include("Couldn't find TeamParticipant")
        end
      end
    end
  end

  ### ✅ **Delete Selected Participants Test**
  path '/api/v1/teams_participants/delete_selected_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'

    delete('delete selected participants') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          item: { type: :array, items: { type: :integer } }
        },
        required: ['item']
      }

      response(200, 'participants deleted successfully') do
        let(:id) { team.id }

        let(:new_user1) do
          User.create!(
            full_name: "User One",
            name: "User1",
            email: "user1@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let(:new_user2) do
          User.create!(
            full_name: "User Two",
            name: "User2",
            email: "user2@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let(:team_participant1) { TeamParticipant.create!(team_id: team.id, user_id: new_user1.id) }
        let(:team_participant2) { TeamParticipant.create!(team_id: team.id, user_id: new_user2.id) }

        let(:payload) { { item: [team_participant1.id, team_participant2.id] } }

        run_test! do |response|
          expect(TeamParticipant.exists?(team_participant1.id)).to be_falsey
          expect(TeamParticipant.exists?(team_participant2.id)).to be_falsey
        end
      end
    end
  end
end
