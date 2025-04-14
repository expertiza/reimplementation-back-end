require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  # Set up roles hierarchy for test users.
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # Create a sample institution.
  let(:institution) { Institution.create!(name: "NC State") }

  # Define our roles.
  let(:instructor_role) { Role.find_or_create_by!(name: "Instructor") }
  let(:ta_role)         { Role.find_or_create_by!(name: "Teaching Assistant", parent_id: instructor_role.id) }
  let(:student_role)    { Role.find_or_create_by!(name: "Student", parent_id: ta_role.id) }

  # Create common users used across tests.
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

  # new_user is used when adding a new participant.
  let(:new_user) do
    User.create!(
      full_name: "New Participant",
      name: "NewParticipant",
      email: "newparticipant@example.com",
      password_digest: "password",
      role_id: student_role.id,
      institution_id: institution.id
    )
  end

  # student_user is used in update_duty and other tests where the current user's ownership is needed.
  let(:student_user) do
    User.create!(
      full_name: "Student Member",
      name: "student_member",
      email: "studentmember@example.com",
      password_digest: "password",
      role_id: student_role.id,
      institution_id: institution.id
    )
  end

  # Create assignments.
  let(:assignment) { Assignment.create!(name: "Sample Assignment", instructor_id: instructor.id) }
  let(:assignment2) { Assignment.create!(name: "Another Assignment", instructor_id: instructor.id) }

  # Create a course.
  let(:course) { Course.create!(name: "Sample Course", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/some/path") }

  # Create teams.
  # For an assignment team, only an assignment is provided.
  let(:team_with_assignment) { Team.create!(assignment_id: assignment.id) }
  # For a course team, only a course is provided.
  let(:team_with_course) { Team.create!(course_id: course.id) }

  # Create a Participant for assignment context.
  let!(:participant_for_assignment) { Participant.create!(user: student_user, assignment: assignment) }
  # And one for course context.
  let!(:participant_for_course) { Participant.create!(user: student_user, course: course) }

  # Create a TeamsParticipant linking the assignment participant to the assignment team.
  let(:teams_participant_assignment) { TeamsParticipant.create!(participant_id: participant_for_assignment.id, team_id: team_with_assignment.id) }
  # Create a TeamsParticipant linking the course participant to the course team.
  let(:teams_participant_course) { TeamsParticipant.create!(participant_id: participant_for_course.id, team_id: team_with_course.id) }

  # By default, use the instructor's token for endpoints.
  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  ##########################################################################
  # update_duty Endpoint Tests
  # This endpoint updates the duty (role) for a TeamsParticipant.
  ##########################################################################
  path '/api/v1/teams_participants/update_duty' do
    put('update participant duty') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          teams_participant_id: { type: :integer },
          teams_participant: {
            type: :object,
            properties: {
              duty_id: { type: :integer }
            },
            required: ['duty_id']
          }
        },
        required: ['teams_participant_id', 'teams_participant']
      }

      # SUCCESS: The current user (owner) updates duty successfully.
      response(200, 'duty updated successfully') do
        # Create a participant for the student_user in an assignment context.
        let!(:participant_for_update) { Participant.create!(user: student_user, assignment: assignment) }
        let(:teams_participant) { TeamsParticipant.create!(team_id: team_with_assignment.id, participant_id: participant_for_update.id) }
        # Use student_user's token for ownership.
        let(:token) { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload) { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq("Duty updated successfully")
          expect(teams_participant.reload.duty_id).to eq(2)
        end
      end

      # FORBIDDEN: A user not owning the TeamsParticipant cannot update duty.
      response(403, 'forbidden: user not authorized to update duty') do
        let(:other_user) do
          User.create!(
            full_name: "Other Student",
            name: "other_student",
            email: "otherstudent@example.com",
            password_digest: "password",
            role_id: student_role.id,
            institution_id: institution.id
          )
        end
        # Create a participant for student_user (the rightful owner) in an assignment context.
        let!(:authorized_participant) { Participant.create!(user: student_user, assignment: assignment) }
        let!(:teams_participant) { TeamsParticipant.create!(team_id: team_with_assignment.id, participant_id: authorized_participant.id) }
        # Use other_user's token, who is not the owner.
        let(:token) { JsonWebToken.encode({ id: other_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload) { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          expect(response.status).to eq(403)
          expect(response.body).to include("not authorized")
        end
      end

      # NOT FOUND: TeamsParticipant record does not exist.
      response(404, 'teams participant not found') do
        let(:payload) { { teams_participant_id: 99999, teams_participant: { duty_id: 2 } } }
        run_test! do |response|
          expect(response.status).to eq(404)
          expect(response.body).to include("Couldn't find TeamsParticipant")
        end
      end
    end
  end

  ##########################################################################
  # list_participants Endpoint Tests
  # This endpoint returns all participants for a given team.
  ##########################################################################
  path '/api/v1/teams_participants/{id}/list_participants' do
    get('list participants') do
      tags 'Teams Participants'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, description: "Team ID"

      # SUCCESS: List participants for a team associated with an assignment.
      response(200, 'list participants for team associated with assignment') do
        let(:id) { team_with_assignment.id }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['assignment']).not_to be_nil
          expect(json['team_participants']).to be_an(Array)
        end
      end

      # SUCCESS: List participants for a team associated with a course.
      response(200, 'list participants for team associated with course') do
        let(:id) { team_with_course.id }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['course']).not_to be_nil
          expect(json['team_participants']).to be_an(Array)
        end
      end

      # FAILURE: Team not found.
      response(404, 'team not found') do
        let(:id) { 0 }
        run_test! do |response|
          expect(response.status).to eq(404)
          expect(response.body).to include("Couldn't find Team")
        end
      end
    end
  end

  ##########################################################################
  # add_participant Endpoint Tests
  # This endpoint adds a participant to a team.
  ##########################################################################
  path '/api/v1/teams_participants/{id}/add_participant' do
    parameter name: 'id', in: :path, type: :integer, description: "Team ID"
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

      # SUCCESS: Participant added successfully to an assignment team.
      response(200, 'participant added successfully to assignment team') do
        let(:id) { team_with_assignment.id }
        let(:payload) { { name: new_user.name } }
        before do
          # Simulate that the team is not full.
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          # Create a Participant record for new_user in an assignment context.
          Participant.create!(user: new_user, assignment: assignment)
        end

        run_test! do |response|
          expect(response.status).to eq(200)
          tp = TeamsParticipant.find_by(team_id: team_with_assignment.id)
          expect(tp).not_to be_nil
        end
      end

      # FAILURE: Participant (or User) not found.
      response(404, 'participant not found') do
        let(:id) { team_with_assignment.id }  # Provide a valid team id
        let!(:user_without_participant) do
          User.create!(
            full_name: "User Without Participant",
            name: "user_without_participant",
            email: "noparticipant@example.com",
            password_digest: "password",
            role_id: student_role.id,
            institution_id: institution.id
          )
        end
        let(:payload) { { name: user_without_participant.name } }

        run_test! do |response|
          expect(response.body).to include("Couldn't find Participant")
        end
      end

    end
  end

  ##########################################################################
  # delete_participants Endpoint Tests
  # This endpoint deletes one or more TeamsParticipant from a team.
  ##########################################################################
  path '/api/v1/teams_participants/{id}/delete_participants' do
    delete('delete participants') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'
      # Define the team id as a path parameter.
      parameter name: :id, in: :path, type: :integer, description: "Team ID"
      # Define the payload: an object with an array of TeamsParticipant IDs under the key 'item'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          item: { type: :array, items: { type: :integer } }
        },
        required: ['item']
      }

      # SUCCESS: Delete multiple participants.
      response(200, 'participants deleted successfully') do
        # Here, we use a team (assignment team) that exists in our fixtures.
        let(:id) { team_with_assignment.id }
        # Setup: Create two user records and corresponding Participant and TeamsParticipant records.
        let(:user1) do
          User.create!(
            full_name: "User One",
            name: "User1",
            email: "user1@example.com",
            password_digest: "password",
            role_id: student_role.id,
            institution_id: institution.id
          )
        end
        let(:user2) do
          User.create!(
            full_name: "User Two",
            name: "User2",
            email: "user2@example.com",
            password_digest: "password",
            role_id: student_role.id,
            institution_id: institution.id
          )
        end
        let(:participant1) { Participant.create!(user: user1, assignment: assignment) }
        let(:participant2) { Participant.create!(user: user2, assignment: assignment) }
        let!(:teams_participant1) { TeamsParticipant.create!(team_id: id, participant_id: participant1.id) }
        let!(:teams_participant2) { TeamsParticipant.create!(team_id: id, participant_id: participant2.id) }
        # Provide the IDs of the TeamsParticipant records to delete.
        let(:payload) { { item: [teams_participant1.id, teams_participant2.id] } }

        run_test! do
          # After deletion, these records should no longer exist.
          expect(TeamsParticipant.exists?(teams_participant1.id)).to be_falsey
          expect(TeamsParticipant.exists?(teams_participant2.id)).to be_falsey
        end
      end

      # SUCCESS: Delete a single participant (the loop should handle a single-element array).
      response(200, 'single participant deleted successfully') do
        let(:id) { team_with_assignment.id }
        let(:user3) do
          User.create!(
            full_name: "User Three",
            name: "User3",
            email: "user3@example.com",
            password_digest: "password",
            role_id: student_role.id,
            institution_id: institution.id
          )
        end
        let!(:participant3) { Participant.create!(user: user3, assignment: assignment) }
        let!(:teams_participant3) { TeamsParticipant.create!(team_id: id, participant_id: participant3.id) }
        let(:payload) { { item: [teams_participant3.id] } }

        run_test! do
          expect(TeamsParticipant.exists?(teams_participant3.id)).to be_falsey
        end
      end

      # FAILURE: When no participant IDs are provided.
      response(200, 'no participants selected') do
        let(:id) { team_with_assignment.id }
        let(:payload) { { item: [] } }
        run_test! do |response|
          expect(response.body).to include("No participants selected")
        end
      end
    end
  end


end
