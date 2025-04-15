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
  let(:teams_participant_assignment) { TeamsParticipant.create!(participant_id: participant_for_assignment.id, team_id: team_with_assignment.id, user_id: participant_for_assignment.user_id) }
  # Create a TeamsParticipant linking the course participant to the course team.
  let(:teams_participant_course) { TeamsParticipant.create!(participant_id: participant_for_course.id, team_id: team_with_course.id, user_id: participant_for_course.user_id) }

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
        let(:teams_participant) { TeamsParticipant.create!(team_id: team_with_assignment.id, participant_id: participant_for_update.id, user_id: participant_for_update.user_id) }
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
        let!(:teams_participant) { TeamsParticipant.create!(team_id: team_with_assignment.id, participant_id: authorized_participant.id, user_id: authorized_participant.user_id) }
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

      # SUCCESS: Participant added successfully to an course team.
      response(200, 'participant added successfully to course team') do
        let(:id) { team_with_course.id }
        let(:payload) { { name: new_user.name } }
        before do
          # Simulate that the team is not full.
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          # Create a Participant record for new_user in an course context.
          Participant.create!(user: new_user, course: course)
        end

        run_test! do |response|
          expect(response.status).to eq(200)
          tp = TeamsParticipant.find_by(team_id: team_with_course.id)
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
  # spec/requests/api/v1/teams_participants_spec.rb

  path '/api/v1/teams_participants/{id}/delete_participants' do
    delete('delete participants') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, description: 'Team ID'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          item: { type: :array, items: { type: :integer } }
        },
        required: ['item']
      }

      # Setup for assignment team
      let(:assignment_team) { Team.create!(assignment_id: assignment.id) }
      let(:assignment_participant1) { Participant.create!(user: student_user, assignment: assignment) }
      let(:assignment_participant2) { Participant.create!(user: new_user, assignment: assignment) }
      let!(:assignment_tp1) { TeamsParticipant.create!(team_id: assignment_team.id, participant_id: assignment_participant1.id, user_id: assignment_participant1.user_id) }
      let!(:assignment_tp2) { TeamsParticipant.create!(team_id: assignment_team.id, participant_id: assignment_participant2.id, user_id: assignment_participant2.user_id) }

      # Setup for course team
      let(:course_team) { Team.create!(course_id: course.id) }
      let(:course_participant1) { Participant.create!(user: student_user, course: course) }
      let(:course_participant2) { Participant.create!(user: new_user, course: course) }
      let!(:course_tp1) { TeamsParticipant.create!(team_id: course_team.id, participant_id: course_participant1.id, user_id: course_participant1.user_id) }
      let!(:course_tp2) { TeamsParticipant.create!(team_id: course_team.id, participant_id: course_participant2.id, user_id: course_participant2.user_id) }

      # SUCCESS: Delete multiple participants successfully (Assignment context)
      response(200, 'participants deleted successfully (assignment)') do
        let(:id) { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id, assignment_tp2.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participants deleted successfully')
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be_falsey
        end
      end

      # SUCCESS: Delete multiple participants successfully (Course context)
      response(200, 'participants deleted successfully (course)') do
        let(:id) { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id, course_tp2.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participants deleted successfully')
          expect(TeamsParticipant.exists?(course_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(course_tp2.id)).to be_falsey
        end
      end

      # SUCCESS: Delete a single participant successfully (Assignment context)
      response(200, 'participant removed successfully (assignment)') do
        let(:id) { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participant removed successfully')
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be_truthy
        end
      end

      # SUCCESS: Delete a single participant successfully (Course context)
      response(200, 'participant removed successfully (course)') do
        let(:id) { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participant removed successfully')
          expect(TeamsParticipant.exists?(course_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(course_tp2.id)).to be_truthy
        end
      end

      # FAILURE: No participants selected for deletion
      response(200, 'no participants selected') do
        let(:id) { assignment_team.id }
        let(:payload) { { payload: { item: [] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('No participants selected')
        end
      end

      # NOT FOUND: Team not found
      response(404, "team not found") do
        let(:id) { 0 } # invalid ID
        let(:payload) { { payload: { item: [999] } } }

        run_test! do |response|
          expect(response.status).to eq(404)
          json = JSON.parse(response.body)
          expect(json['error']).to eq("Couldn't find Team")
        end
      end

    end
  end


end
