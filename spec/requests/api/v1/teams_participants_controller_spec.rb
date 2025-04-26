require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the full roles hierarchy once, to be shared by all examples.
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # --------------------------------------------------------------------------
  # Common Test Data
  # --------------------------------------------------------------------------
  # A single institution to house all users.
  let(:institution) { Institution.create!(name: "NC State") }

  # An instructor user who will own assignments and courses.
  let(:instructor) do
    User.create!(
      name:                "profa",
      password_digest:     "password",
      role_id:              @roles[:instructor].id,
      full_name:           "Prof A",
      email:               "testuser@example.com",
      mru_directory_path:  "/home/testuser",
      institution_id:      institution.id
    )
  end

  # A generic "new participant" used when adding to teams
  let(:new_user) do
    User.create!(
      full_name:       "New Participant",
      name:            "NewParticipant",
      email:           "newparticipant@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # A student user used for ownership checks in update_duty, list, etc.
  let(:student_user) do
    User.create!(
      full_name:       "Student Member",
      name:            "student_member",
      email:           "studentmember@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # --------------------------------------------------------------------------
  # Primary Resources
  # --------------------------------------------------------------------------
  # Two assignments: one main and one alternate, both owned by the instructor.
  let!(:assignment)  { Assignment.create!(name: "Sample Assignment", instructor_id: instructor.id) }
  let(:assignment2)  { Assignment.create!(name: "Another Assignment", instructor_id: instructor.id) }

  # A single course, also owned by the instructor.
  let(:course) do
    Course.create!(
      name:            "Sample Course",
      instructor_id:   instructor.id,
      institution_id:  institution.id,
      directory_path:  "/some/path"
    )
  end

  # --------------------------------------------------------------------------
  # Team & Participant Setup
  # --------------------------------------------------------------------------
  # Create one team per context (assignment vs. course) via STI subclasses:
  let(:team_with_assignment) { AssignmentTeam.create!(parent_id: assignment.id) }
  let(:team_with_course)     { CourseTeam.create!(parent_id: course.id)     }

  # Create one participant record per context for a baseline student_user:
  let!(:participant_for_assignment) do
    AssignmentParticipant.create!(
      parent_id: assignment.id,
      user:      student_user,
      handle:    student_user.name
    )
  end
  let!(:participant_for_course) do
    CourseParticipant.create!(
      parent_id: course.id,
      user:      student_user,
      handle:    student_user.name
    )
  end

  # Link those participants into TeamsParticipant join records:
  let(:teams_participant_assignment) do
    TeamsParticipant.create!(
      participant_id: participant_for_assignment.id,
      team_id:        team_with_assignment.id,
      user_id:        participant_for_assignment.user_id
    )
  end
  let(:teams_participant_course) do
    TeamsParticipant.create!(
      participant_id: participant_for_course.id,
      team_id:        team_with_course.id,
      user_id:        participant_for_course.user_id
    )
  end

  # --------------------------------------------------------------------------
  # Authentication Helper
  # --------------------------------------------------------------------------
  # Generate a valid JWT for the instructor by default.
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
          teams_participant:    { type: :object, properties: { duty_id: { type: :integer } }, required: ['duty_id'] }
        },
        required: ['teams_participant_id', 'teams_participant']
      }

      # -- SUCCESS: Owner updates the duty of their own TeamsParticipant --
      response(200, 'duty updated successfully') do
        let!(:participant_for_update) do
          AssignmentParticipant.create!(
            parent_id: assignment.id,
            user:      student_user,
            handle:    student_user.name
          )
        end
        let(:teams_participant) do
          TeamsParticipant.create!(
            team_id:        team_with_assignment.id,
            participant_id: participant_for_update.id,
            user_id:        participant_for_update.user_id
          )
        end
        let(:token)         { JsonWebToken.encode({ id: student_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload)       { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq("Duty updated successfully")
          expect(teams_participant.reload.duty_id).to eq(2)
        end
      end

      # -- FORBIDDEN: A different user (non-owner) attempts update --
      response(403, 'forbidden: user not authorized') do
        let(:other_user) do
          User.create!(
            full_name:       "Other",
            name:            "other",
            email:           "other@example.com",
            password_digest: "pw",
            role_id:          @roles[:student].id,
            institution_id:  institution.id
          )
        end
        let!(:authorized_participant) do
          AssignmentParticipant.create!(
            parent_id: assignment.id,
            user:      student_user,
            handle:    student_user.name
          )
        end
        let!(:teams_participant) do
          TeamsParticipant.create!(
            team_id:        team_with_assignment.id,
            participant_id: authorized_participant.id,
            user_id:        authorized_participant.user_id
          )
        end
        let(:token)         { JsonWebToken.encode({ id: other_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:payload)       { { teams_participant_id: teams_participant.id, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          expect(response.status).to eq(403)
          expect(response.body).to include("not authorized")
        end
      end

      # -- NOT FOUND: No TeamsParticipant matches the given ID --
      response(404, 'teams participant not found') do
        let(:payload) { { teams_participant_id: 0, teams_participant: { duty_id: 2 } } }

        run_test! do |response|
          expect(response.status).to eq(404)
          expect(response.body).to include("Couldn't find TeamsParticipant")
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

      # -- SUCCESS: Assignment team returns its participants and assignment info --
      response(200, 'for assignment') do
        let(:id) { team_with_assignment.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['assignment']).not_to be_nil
          expect(json['team_participants']).to be_an(Array)
        end
      end

      # -- SUCCESS: Course team returns its participants and course info --
      response(200, 'for course') do
        let(:id) { team_with_course.id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['team']).not_to be_nil
          expect(json['course']).not_to be_nil
          expect(json['team_participants']).to be_an(Array)
        end
      end

      # -- NOT FOUND: No Team matches the given ID --
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
  ##########################################################################
  path '/api/v1/teams_participants/{id}/add_participant' do
    post('add participant') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'id', in: :path, type: :integer, description: "Team ID"
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: { name: { type: :string } },
        required: ['name']
      }

      # -- SUCCESS: Add to AssignmentTeam when space available and participant exists --
      response(200, 'added to assignment') do
        let(:id)      { team_with_assignment.id }
        let(:payload) { { name: new_user.name } }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          AssignmentParticipant.create!(parent_id: assignment.id, user: new_user, handle: new_user.name)
        end

        run_test! do
          expect(TeamsParticipant.find_by(team_id: team_with_assignment.id)).not_to be_nil
        end
      end

      # -- SUCCESS: Add to CourseTeam when space available and participant exists --
      response(200, 'added to course') do
        let(:id)      { team_with_course.id }
        let(:payload) { { name: new_user.name } }

        before do
          allow_any_instance_of(Team).to receive(:full?).and_return(false)
          CourseParticipant.create!(parent_id: course.id, user: new_user, handle: new_user.name)
        end

        run_test! do
          expect(TeamsParticipant.find_by(team_id: team_with_course.id)).not_to be_nil
        end
      end

      # -- NOT FOUND: Participant record missing for given name --
      response(404, 'participant not found') do
        let(:id)                                     { team_with_assignment.id }
        let!(:user_without_participant)              { User.create!(full_name: "User Without Participant", name: "no_part", email: "no@example.com", password_digest: "pw", role_id: @roles[:student].id, institution_id: institution.id) }
        let(:payload)                                { { name: user_without_participant.name } }

        run_test! do
          expect(response.body).to include("Couldn't find Participant")
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
        properties: { item: { type: :array, items: { type: :integer } } },
        required: ['item']
      }

      # -- SETUP: Two participants linked to an AssignmentTeam --
      let(:assignment_team)         { AssignmentTeam.create!(parent_id: assignment.id) }
      let(:assignment_participant1) { AssignmentParticipant.create!(parent_id: assignment.id, user: student_user, handle: student_user.name) }
      let(:assignment_participant2) { AssignmentParticipant.create!(parent_id: assignment.id, user: new_user,       handle: new_user.name) }
      let!(:assignment_tp1)         { TeamsParticipant.create!(team_id: assignment_team.id, participant_id: assignment_participant1.id, user_id: assignment_participant1.user_id) }
      let!(:assignment_tp2)         { TeamsParticipant.create!(team_id: assignment_team.id, participant_id: assignment_participant2.id, user_id: assignment_participant2.user_id) }

      # -- SETUP: Two participants linked to a CourseTeam --
      let(:course_team)         { CourseTeam.create!(parent_id: course.id) }
      let(:course_participant1) { CourseParticipant.create!(parent_id: course.id, user: student_user, handle: student_user.name) }
      let(:course_participant2) { CourseParticipant.create!(parent_id: course.id, user: new_user,       handle: new_user.name) }
      let!(:course_tp1)         { TeamsParticipant.create!(team_id: course_team.id, participant_id: course_participant1.id, user_id: course_participant1.user_id) }
      let!(:course_tp2)         { TeamsParticipant.create!(team_id: course_team.id, participant_id: course_participant2.id, user_id: course_participant2.user_id) }

      # -- SUCCESS: Delete both participants from AssignmentTeam --
      response(200, 'deleted (assignment)') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id, assignment_tp2.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participants deleted successfully')
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be_falsey
        end
      end

      # -- SUCCESS: Delete both participants from CourseTeam --
      response(200, 'deleted (course)') do
        let(:id)      { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id, course_tp2.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participants deleted successfully')
          expect(TeamsParticipant.exists?(course_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(course_tp2.id)).to be_falsey
        end
      end

      # -- SUCCESS: Remove a single participant from AssignmentTeam --
      response(200, 'removed (assignment)') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [assignment_tp1.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participant removed successfully')
          expect(TeamsParticipant.exists?(assignment_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(assignment_tp2.id)).to be_truthy
        end
      end

      # -- SUCCESS: Remove a single participant from CourseTeam --
      response(200, 'removed (course)') do
        let(:id)      { course_team.id }
        let(:payload) { { payload: { item: [course_tp1.id] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Participant removed successfully')
          expect(TeamsParticipant.exists?(course_tp1.id)).to be_falsey
          expect(TeamsParticipant.exists?(course_tp2.id)).to be_truthy
        end
      end

      # -- SUCCESS: No items selected yields a specific error message --
      response(200, 'no participants selected') do
        let(:id)      { assignment_team.id }
        let(:payload) { { payload: { item: [] } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('No participants selected')
        end
      end

      # -- NOT FOUND: Team with given ID does not exist --
      response(404, "team not found") do
        let(:id)      { 0 }
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
