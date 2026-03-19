require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Student Teams API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  #
  # --- USERS ---
  #
  let(:student_user) {
    User.create!(
      name: "student1",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student One",
      email: "student1@example.com"
    )
  }

  let(:student_user2) {
    User.create!(
      name: "student2",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Two",
      email: "student2@example.com"
    )
  }

  let(:ta_user) {
    User.create!(
      name: "ta123",
      password_digest: "password",
      role_id: @roles[:ta].id,
      full_name: "Teaching Assistant",
      email: "ta@example.com"
    )
  }

  #
  # Assignment + Participants
  #
  let(:assignment) { Assignment.create!(name: "A1", instructor_id: student_user.id) }

  let(:participant1) { AssignmentParticipant.create!(user: student_user, parent_id: assignment.id, handle: "u1") }
  let(:participant2) { AssignmentParticipant.create!(user: student_user2, parent_id: assignment.id, handle: "u2") }

  #
  # Teams
  #
  let(:team1) { AssignmentTeam.create!(name: "Team1", parent_id: assignment.id) }
  let(:team2) { AssignmentTeam.create!(name: "Team2", parent_id: assignment.id) }

  before do
    team1.add_member(participant1)
    team2.add_member(participant2)
  end

  #
  # Authorization tokens
  #
  let(:token) { JsonWebToken.encode({ id: student_user.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let(:token2) { JsonWebToken.encode({ id: student_user2.id }) }
  let(:ta_token) { JsonWebToken.encode({ id: ta_user.id }) }

  #
  # --- TESTS ---
  #

  #
  # GET /student_teams/view
  #
  path "/student_teams/view" do
    get("View student team") do
      tags "Student Teams"
      produces "application/json"
      parameter name: "student_id", in: :query, type: :integer
      parameter name: "Authorization", in: :header, type: :string, required: true

      response(200, "Student is on a team") do
        let(:student_id) { participant1.id }
        run_test!
      end

      response(200, "Student not on any team") do
        before do
          TeamsParticipant.where(participant: participant1).delete_all
        end

        let(:student_id) { participant1.id }
        run_test!
      end

      response(403, "Not allowed") do
        let(:Authorization) { "Bearer #{token2}" }
        let(:student_id) { participant1.id }
        run_test!
      end

      response(403, "TA cannot access") do
        let(:Authorization) { "Bearer #{ta_token}" }
        let(:student_id) { participant1.id }
        run_test!
      end
    end
  end


  #
  # POST /student_teams
  #
  path "/student_teams" do
    post("Create team") do
      tags "Student Teams"
      consumes "application/json"

      parameter name: "Authorization", in: :header, type: :string, required: true
      parameter name: :team, in: :body, schema: {
        type: :object,
        properties: {
          team: {
            type: :object,
            properties: { name: { type: :string } },
            required: %w[name]
          },
          assignment_id: { type: :integer },
          student_id: { type: :integer }
        },
        required: %w[team assignment_id student_id]
      }

      #
      # Successful create
      #
      response(200, "Create successful") do
        let(:team) {
          {
            team: { name: "NewTeam" },
            assignment_id: assignment.id,
            student_id: participant1.id
          }
        }
        run_test!
      end

      #
      # Duplicate team name
      #
      response(422, "Duplicate name") do
        before { AssignmentTeam.create!(name: "NewTeam", parent_id: assignment.id) }

        let(:team) {
          {
            team: { name: "NewTeam" },
            assignment_id: assignment.id,
            student_id: participant1.id
          }
        }
        run_test!
      end

      response(403, "Unauthorized") do
        let(:Authorization) { "Bearer #{ta_token}" }
        let(:team) {
          {
            team: { name: "X" },
            assignment_id: assignment.id,
            student_id: participant1.id
          }
        }
        run_test!
      end
    end
  end


  #
  # PUT /student_teams
  #
  path "/student_teams/update" do
    put("Update team name") do
      tags "Student Teams"
      consumes "application/json"

      parameter name: "Authorization", in: :header, type: :string, required: true
      parameter name: :student_id, in: :query, type: :integer
      let(:student_id) { participant1.id }

      parameter name: :team, in: :body, schema: {
        type: :object,
        properties: {
          team: {
            type: :object,
            properties: { name: { type: :string } }
          },
        },
        required: %w[team]
      }

      #
      # Successful update
      #
      response(200, "Update successful") do
        let(:team) {
          {
            team: { name: "RenamedTeam" },
            team_id: team1.id,
          }
        }
        run_test!
      end

      #
      # Duplicate name
      #
      response(422, "Duplicate name") do
        before { AssignmentTeam.create!(name: "RenamedTeam", parent_id: assignment.id) }

        let(:team) {
          {
            team: { name: "RenamedTeam" },
            team_id: team1.id,
          }
        }
        run_test!
      end

      response(403, "Unauthorized") do
        let(:Authorization) { "Bearer #{token2}" }
        let(:team) {
          {
            team: { name: "AnotherName" },
            team_id: team1.id,
          }
        }
        run_test!
      end
    end
  end


  #
  # PUT /student_teams/leave
  #
  path "/student_teams/leave" do
    put("Leave team") do
      tags "Student Teams"
      parameter name: "Authorization", in: :header, type: :string, required: true
      parameter name: "student_id", in: :query, type: :integer, required: true

      response(200, "Leave successful") do
        let(:student_id) { participant1.id }
        run_test!
      end

      response(403, "Unauthorized") do
        let(:Authorization) { "Bearer #{token2}" }
        let(:student_id) { participant1.id }
        run_test!
      end

      response(403, "TA cannot leave") do
        let(:Authorization) { "Bearer #{ta_token}" }
        let(:student_id) { participant1.id }
        run_test!
      end
    end
  end
end