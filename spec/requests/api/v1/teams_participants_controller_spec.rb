require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:institution) { Institution.create!(name: "NC State2") }

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

  let(:teams_user) do
    TeamsUser.create!(
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

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          teams_user_id: { type: :integer },
          teams_user: {
            type: :object,
            properties: {
              duty_id: { type: :integer }
            },
            required: ['duty_id']
          }
        },
        required: ['teams_user_id', 'teams_user']
      }

      response(200, 'duty updated successfully') do
        let(:payload) do
          {
            teams_user_id: teams_user.id,
            teams_user: { duty_id: 2 }
          }
        end

        run_test!
      end

      response(404, 'team user not found') do
        let(:payload) do
          {
            teams_user_id: 99999,  # Non-existing ID
            teams_user: { duty_id: 2 }
          }
        end

        run_test! do |response|
          expect(response.body).to include("Couldn't find TeamsUser")
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
        let(:id) { 99999 } # Ensure non-existing team ID

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
    parameter name: 'id', in: :path, type: :integer, description: 'TeamsUser ID'

    delete('delete participant') do
      tags 'Teams Participants'
      produces 'application/json'

      response(200, 'participant deleted successfully') do
        let(:id) { teams_user.id }

        run_test! do |response|
          expect(TeamsUser.exists?(teams_user.id)).to be_falsey
        end
      end

      response(404, 'not found') do
        let(:id) { 0 }

        run_test! do |response|
          expect(response.body).to include("Couldn't find TeamsUser")
        end
      end
    end
  end

  ### ✅ **Delete Selected Participants Test**
  path '/api/v1/teams_participants/delete_selected_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'

    delete('delete selected participants') do
      tags 'Teams Participants'
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

        let(:teams_user1) { TeamsUser.create!(team_id: team.id, user_id: new_user1.id) }
        let(:teams_user2) { TeamsUser.create!(team_id: team.id, user_id: new_user2.id) }

        # let(:payload) { {item: [teams_user1.id, teams_user2.id] }}


        let(:payload) { { item: [teams_user.id] } }


        run_test! do |response|
          # expect(TeamsUser.exists?(teams_user1.id)).to be_falsey
          # expect(TeamsUser.exists?(teams_user2.id)).to be_falsey
          expect(TeamsUser.exists?(teams_user.id)).to be_falsey
        end
      end
    end
  end
end
