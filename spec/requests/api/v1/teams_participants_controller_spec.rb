require 'swagger_helper'
require 'json_web_token'
require 'securerandom'

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
  let(:assignment)  { Assignment.create!(name: "Sample Assignment",  instructor_id: instructor.id) }
  let(:assignment2) { Assignment.create!(name: "Another Assignment", instructor_id: instructor.id) }

  # Create a course.
  let(:course) { Course.create!(
    name:           "Sample Course",
    instructor_id:  instructor.id,
    institution_id: institution.id,
    directory_path: "/some/path"
  ) }

  # Create teams (now with unique names).
  let(:team_with_assignment) do
    Team.create!(
      assignment_id: assignment.id,
      name:          "assignment_team_#{assignment.id}_#{SecureRandom.hex(4)}"
    )
  end

  let(:team_with_course) do
    Team.create!(
      course_id: course.id,
      name:      "course_team_#{course.id}_#{SecureRandom.hex(4)}"
    )
  end

  # Create Participants.
  let!(:participant_for_assignment) { Participant.create!(user: student_user, assignment: assignment) }
  let!(:participant_for_course)     { Participant.create!(user: student_user, course:     course) }

  # **Drop all `user_id:` here** — TeamsParticipant has only team_id & participant_id.
  let(:teams_participant_assignment) do
    TeamsParticipant.create!(
      participant_id: participant_for_assignment.id,
      team_id:        team_with_assignment.id
    )
  end
  let(:teams_participant_course) do
    TeamsParticipant.create!(
      participant_id: participant_for_course.id,
      team_id:        team_with_course.id
    )
  end

  # By default, use the instructor's token for endpoints.
  let(:token)         { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  ##########################################################################
  # update_duty Endpoint Tests
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

      # SUCCESS: owner updates duty
      response(200, 'duty updated successfully') do
        let!(:participant_for_update) { Participant.create!(user: student_user, assignment: assignment) }
        let(:teams_participant) do
          TeamsParticipant.create!(
            team_id:        team_with_assignment.id,
            participant_id: participant_for_update.id
          )
        end

        let(:token)         { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload)       { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |_response|
          expect(teams_participant.reload.duty_id).to eq(2)
        end
      end

      # FORBIDDEN: non-owner cannot update
      response(403, 'forbidden: user not authorized to update duty') do
        let(:other_user) do
          User.create!(
            full_name:      "Other Student",
            name:           "other_student",
            email:          "otherstudent@example.com",
            password_digest:"password",
            role_id:        student_role.id,
            institution_id: institution.id
          )
        end

        let!(:authorized_participant) { Participant.create!(user: student_user, assignment: assignment) }
        let!(:teams_participant) do
          TeamsParticipant.create!(
            team_id:        team_with_assignment.id,
            participant_id: authorized_participant.id
          )
        end

        let(:token)         { JsonWebToken.encode({ id: other_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload)       { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          expect(response.status).to eq(403)
        end
      end

      # NOT FOUND
      response(404, 'teams participant not found') do
        let(:payload) { { teams_participant_id: 99_999, teams_participant: { duty_id: 2 } } }
        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end

  ##########################################################################
  # list_participants Endpoint Tests
  ##########################################################################
  path '/api/v1/teams_participants/{id}/list_participants' do
    get('list participants') do
      tags 'Teams Participants'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, description: "Team ID"

      response(200, 'assignment team participants') do
        let(:id) { team_with_assignment.id }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['assignment']).not_to be_nil
        end
      end

      response(200, 'course team participants') do
        let(:id) { team_with_course.id }
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['course']).not_to be_nil
        end
      end

      response(404, 'team not found') do
        let(:id) { 0 }
        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end

  ##########################################################################
  # add_participant Endpoint Tests
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

      response(200, 'participant added successfully to assignment team') do
        let(:id)      { team_with_assignment.id }
        let(:payload) { { name: new_user.name } }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          allow_any_instance_of(Team).to receive(:can_participant_join_team?).and_return(true)
          Participant.create!(user: new_user, assignment: assignment)
        end

        run_test! do |_response|
          expect(TeamsParticipant.exists?(team_id: team_with_assignment.id)).to be true
        end
      end

      response(200, 'participant added successfully to course team') do
        let(:id)      { team_with_course.id }
        let(:payload) { { name: new_user.name } }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          allow_any_instance_of(Team).to receive(:can_participant_join_team?).and_return(true)
          Participant.create!(user: new_user, course: course)
        end

        run_test! do |_response|
          expect(TeamsParticipant.exists?(team_id: team_with_course.id)).to be true
        end
      end

      response(404, 'participant not found') do
        let(:id)      { team_with_assignment.id }
        let!(:user_without_participant) do
          User.create!(
            full_name:      "User Without Participant",
            name:           "user_without_participant",
            email:          "noparticipant@example.com",
            password_digest:"password",
            role_id:        student_role.id,
            institution_id: institution.id
          )
        end
        let(:payload) { { name: user_without_participant.name } }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end

  ##########################################################################
  # delete_participants Endpoint Tests
  ##########################################################################
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

      let(:assignment_team) do
        Team.create!(
          assignment_id: assignment.id,
          name:          "assignment_del_team_#{assignment.id}_#{SecureRandom.hex(4)}"
        )
      end
      let(:assignment_participant1) { Participant.create!(user: student_user, assignment: assignment) }
      let(:assignment_participant2) { Participant.create!(user: new_user,    assignment: assignment) }
      let!(:assignment_tp1) do
        TeamsParticipant.create!(
          team_id:        assignment_team.id,
          participant_id: assignment_participant1.id
        )
      end
      let!(:assignment_tp2) do
        TeamsParticipant.create!(
          team_id:        assignment_team.id,
          participant_id: assignment_participant2.id
        )
      end

      let(:course_team) do
        Team.create!(
          course_id: course.id,
          name:      "course_del_team_#{course.id}_#{SecureRandom.hex(4)}"
        )
      end
      let(:course_participant1) { Participant.create!(user: student_user, course: course) }
      let(:course_participant2) { Participant.create!(user: new_user,    course: course) }
      let!(:course_tp1) do
        TeamsParticipant.create!(
          team_id:        course_team.id,
          participant_id: course_participant1.id
        )
      end
      let!(:course_tp2) do
        TeamsParticipant.create!(
          team_id:        course_team.id,
          participant_id: course_participant2.id
        )
      end

      response(200, 'participants deleted successfully (assignment)') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id, assignment_tp2.id] } } }

        run_test! do |_response|
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be false
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be false
        end
      end

      response(200, 'participants deleted successfully (course)') do
        let(:id)      { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id, course_tp2.id] } } }

        run_test! do |_response|
          expect(TeamsParticipant.exists?(course_tp1.id)).to be false
          expect(TeamsParticipant.exists?(course_tp2.id)).to be false
        end
      end

      response(200, 'participant removed successfully (assignment)') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id] } } }

        run_test! do |_response|
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be false
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be true
        end
      end

      response(200, 'participant removed successfully (course)') do
        let(:id)      { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id] } } }

        run_test! do |_response|
          expect(TeamsParticipant.exists?(course_tp1.id)).to be false
          expect(TeamsParticipant.exists?(course_tp2.id)).to be true
        end
      end

      response(200, 'no participants selected') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [] } } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('No participants selected')
        end
      end

      response(404, 'team not found') do
        let(:id)      { 0 }
        let(:payload) { { payload: { item: [999] } } }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
