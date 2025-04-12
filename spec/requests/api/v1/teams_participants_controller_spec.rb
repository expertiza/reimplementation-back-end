require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:institution) { Institution.create!(name: "NC State") }

  let(:instructor_role) { Role.find_or_create_by!(name: "Instructor") }
  let(:ta_role)         { Role.find_or_create_by!(name: "Teaching Assistant", parent_id: instructor_role.id) }
  let(:student_role)    { Role.find_or_create_by!(name: "Student", parent_id: ta_role.id) }

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

  let(:assignment) { Assignment.create!(name: "Sample Assignment", instructor_id: instructor.id) }
  let(:assignment1) { Assignment.create!(name: "Sample Assignment1", instructor_id: instructor.id) }

  let(:team) { Team.create!(assignment_id: assignment.id) }
  let(:empty_team) { Team.create!(assignment_id: assignment1.id) }

  let(:new_user) do
    User.create!(
      full_name: "New Participant",
      name: "NewParticipant",
      email: "newparticipant@example.com",
      password_digest: "password",
      role_id: student_role.id
    )
  end

  let!(:new_participant) do
    Participant.create!(user: new_user, assignment: assignment1)
  end

  let(:existing_user) do
    User.create!(
      full_name: "Test Participant",
      name: "Test",
      email: "participant@example.com",
      password_digest: "password",
      role_id: student_role.id
    )
  end

  let!(:participant) do
    Participant.create!(user: existing_user, assignment: assignment)
  end

  let(:team_participant) do
    TeamParticipant.create!(participant_id: participant.id, team_id: team.id)
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/teams_participants/update_duty' do
    put('update participant duty') do
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

      response(200, 'duty updated successfully by a valid team member') do
        let(:student_user) do
          User.create!(
            full_name: "Student Member",
            name: "student_member",
            email: "studentmember@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let!(:participant) { Participant.create!(user: student_user, assignment: assignment) }

        let(:team_participant) { TeamParticipant.create!(team_id: team.id, participant_id: participant.id) }

        let(:token) { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        let(:payload) do
          {
            team_participant_id: team_participant.id,
            team_participant: { duty_id: 2 }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq("Duty updated successfully")
          expect(team_participant.reload.duty_id).to eq(2)
        end
      end

      response(403, 'forbidden: student not on team tries to update duties') do
        let(:other_user) do
          User.create!(
            full_name: "Another Student",
            name: "another_student",
            email: "anotherstudent@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let!(:unauthorized_participant) { Participant.create!(user: other_user, assignment: assignment) }

        let!(:authorized_user) do
          User.create!(
            full_name: "Authorized Student",
            name: "auth_student",
            email: "authstudent@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let!(:participant_on_team) { Participant.create!(user: authorized_user, assignment: assignment) }

        let!(:team_participant) { TeamParticipant.create!(team_id: team.id, participant_id: participant_on_team.id) }

        let(:token) { JsonWebToken.encode({ id: other_user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        let(:payload) do
          {
            team_participant_id: team_participant.id,
            team_participant: { duty_id: 2 }
          }
        end

        run_test! do |response|
          expect(response.status).to eq(403)
          expect(response.body).to include("not authorized")
        end
      end


      response(404, 'team participant not found') do
        let(:student_user) do
          User.create!(
            full_name: "Student Member",
            name: "student_member",
            email: "studentmember@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let(:token) { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        let(:payload) do
          {
            team_participant_id: 99999,
            team_participant: { duty_id: 2 }
          }
        end

        run_test! do |response|
          expect(response.status).to eq(404)
          expect(response.body).to include("Couldn't find TeamParticipant")
        end
      end
    end
  end

  path '/api/v1/teams_participants/add_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer

    post('add participant') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        },
        required: ['name']
      }

      response(200, 'participant added successfully') do
        let(:payload) { { name: new_user.name } }
        let(:id) { empty_team.id }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)

          # Make sure this assignment is the one attached to the empty_team
          expect(empty_team.assignment_id).to eq(assignment1.id)

          # Ensure that the participant is created correctly
          Participant.create!(user: new_user, assignment: assignment1)
        end

        run_test! do |response|
          expect(response.status).to eq(200)
          tp = TeamParticipant.find_by(team_id: empty_team.id)
          expect(tp).not_to be_nil
        end
      end

      response(404, 'participant not found') do
        let(:payload) { { name: 'Invalid User' } }
        let(:id) { empty_team.id }

        run_test! do |response|
          expect(response.body).to include("Couldn't find Participant")
        end
      end
    end
  end


  path '/api/v1/teams_participants/delete_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer

    delete('delete participant') do
      tags 'Teams Participants'
      produces 'application/json'

      response(200, 'participant deleted successfully') do
        let(:id) { team_participant.id }

        run_test! do
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

  path '/api/v1/teams_participants/delete_selected_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer

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

        let(:user1) do
          User.create!(full_name: "User One", name: "User1", email: "user1@example.com", password_digest: "password", role_id: student_role.id)
        end

        let(:user2) do
          User.create!(full_name: "User Two", name: "User2", email: "user2@example.com", password_digest: "password", role_id: student_role.id)
        end

        let(:participant1) { Participant.create!(user: user1, assignment: assignment) }
        let(:participant2) { Participant.create!(user: user2, assignment: assignment) }

        let!(:team_participant1) { TeamParticipant.create!(team_id: team.id, participant_id: participant1.id) }
        let!(:team_participant2) { TeamParticipant.create!(team_id: team.id, participant_id: participant2.id) }

        let(:payload) { { item: [team_participant1.id, team_participant2.id] } }

        run_test! do
          expect(TeamParticipant.exists?(team_participant1.id)).to be_falsey
          expect(TeamParticipant.exists?(team_participant2.id)).to be_falsey
        end
      end
    end
  end
end
