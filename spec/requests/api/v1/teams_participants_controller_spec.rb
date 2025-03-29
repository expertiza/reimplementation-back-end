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

  let(:assignment) do
    Assignment.create!(
      name: "Sample Assignment",
      instructor_id: instructor.id
    )
  end

  let(:assignment1) do
    Assignment.create!(
      name: "Sample Assignment1",
      instructor_id: instructor.id
    )
  end

  # This team is used for tests that require a pre-existing participant.
  let(:team) do
    Team.create!(
      assignment_id: assignment.id
    )
  end

  # Create an extra empty team (no participants) for the add participant test.
  let(:empty_team) do
    Team.create!(
      assignment_id: assignment1.id
    )
  end

  # Create a new participant (as a User) to be added.
  let(:new_participant) do
    User.create!(
      full_name: "New Participant",
      name: "NewParticipant",
      email: "newparticipant@example.com",
      password_digest: "password",
      role_id: student_role.id
    )
  end

  # For update and delete tests, we create a participant and add them to the team.
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

        let(:team_participant) { TeamParticipant.create!(team_id: team.id, user_id: student_user.id) }

        # Token should belong to the student who is actually on the team
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
        let(:other_student) do
          User.create!(
            full_name: "Another Student",
            name: "another_student",
            email: "anotherstudent@example.com",
            password_digest: "password",
            role_id: student_role.id
          )
        end

        let(:team_participant) { TeamParticipant.create!(team_id: team.id, user_id: participant.id) }

        # Token belongs to another student NOT on this team
        let(:token) { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }

        let(:payload) do
          {
            team_participant_id: team_participant.id,
            team_participant: { duty_id: 2 }
          }
        end

        run_test! do |response|
          expect(response.status).to eq(403)
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

        # Provide a valid student user's token, allowing authorization check to pass
        let(:token) { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }

        let(:payload) do
          {
            team_participant_id: 99999,  # Non-existing ID
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

      response(200, 'participant added successfully') do
        let(:payload) { { user: { name: new_participant.name } } }
        let(:id) { empty_team.id }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)

          # IMPORTANT FIX HERE:
          # Ensure AssignmentParticipant matches empty_team's assignment (assignment1)
          AssignmentParticipant.create!(
            user_id: new_participant.id,
            assignment_id: assignment1.id,  # <-- FIXED THIS LINE
            handle: new_participant.name
          )

          expect(
            AssignmentParticipant.find_by(
              user_id: new_participant.id,
              assignment_id: assignment1.id
            )
          ).not_to be_nil

          TeamParticipant.where(user_id: new_participant.id).destroy_all
        end

        run_test! do |response|
          expect(response.status).to eq(200)
          tp = TeamParticipant.find_by(team_id: empty_team.id, user_id: new_participant.id)
          expect(tp).not_to be_nil
        end
      end





      response(404, 'participant not found') do
        let(:payload) { { user: { name: 'Invalid User' } } }
        let(:id) { empty_team.id }
        run_test! do |response|
          expect(response.body).to include("Couldn't find Participant")
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
