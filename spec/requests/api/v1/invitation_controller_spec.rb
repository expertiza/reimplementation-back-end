require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Invitations API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  #
  # --- USERS ---
  #

  let(:ta) do
    User.create!(
      name: "ta",
      password_digest: "password",
      role_id: @roles[:ta].id,
      full_name: "Teaching Assistant",
      email: "ta@example.com"
    )
  end

  let(:user1) do
    User.create!(
      name: "student",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Name",
      email: "student@example.com"
    )
  end

  let(:user2) do
    User.create!(
      name: "student2",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Two",
      email: "student2@example.com"
    )
  end

  let(:prof) {
    create(:user,
           role_id: @roles[:instructor].id,
           name: "profa",
           full_name: "Prof A",
           email: "profa@example.com")
  }

  #
  # --- ASSIGNMENT + PARTICIPANTS + TEAMS ---
  #
  let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: prof.id) }

  let(:token) { JsonWebToken.encode({ id: user1.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let(:ta_token) { JsonWebToken.encode({ id: ta.id }) }

  let(:team1) { AssignmentTeam.create!(name: "Team1", parent_id: assignment.id) }
  let(:team2) { AssignmentTeam.create!(name: "Team2", parent_id: assignment.id) }

  let(:participant1) { AssignmentParticipant.create!(user: user1, parent_id: assignment.id, handle: 'user1_handle') }
  let(:participant2) { AssignmentParticipant.create!(user: user2, parent_id: assignment.id, handle: 'user2_handle') }


  before do
    # assign participants to teams
    team1.add_participant(participant1)
    team2.add_participant(participant2)
  end

  #
  # Existing invitation instance
  #
  let(:invitation) {
    Invitation.create!(
      from_participant: participant1,
      to_participant: participant2,
      assignment: assignment,
      reply_status: InvitationValidator::WAITING_STATUS
    )
  }

  let(:invitation2) {
    Invitation.create!(
      from_participant: participant2,
      to_participant: participant1,
      assignment: assignment,
      reply_status: InvitationValidator::WAITING_STATUS
    )
  }

  #
  # --- TESTS ---
  #
  path "/invitations" do
    get("list invitations") do
      tags "Invitations"
      produces "application/json"
      parameter name: 'Authorization', in: :header, type: :string, required: true
      let(:Authorization) { "Bearer #{ta_token}" }
      response(200, "Success") do
        run_test!
      end
    end
  end

  path "/invitations" do
    #
    # POST /invitations
    #
    post("create invitation") do
      tags "Invitations"
      consumes "application/json"
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      parameter name: :invitation, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: { type: :integer },
          username: { type: :string }, 
        },
        required: %w[assignment_id username]
      }

      #
      # SUCCESS CASE
      #
      response(201, "Create successful") do
        let(:invitation) {
          {
            assignment_id: assignment.id,
            username: user2.name
          }
        }

        run_test!
      end

      #
      # Invalid — user not found
      #
      response(404, "User not found") do
        let(:invitation) {
          {
            assignment_id: assignment.id,
            username: "UNKNOWN_USER"
          }
        }

        run_test!
      end

      #
      # Invalid — user exists but not participant
      #
      response(404, "Participant not found") do
        let(:non_participant_user) { create(:user, name: "randomuser") }

        let(:invitation) {
          {
            assignment_id: assignment.id,
            username: non_participant_user.name
          }
        }

        run_test!
      end
    end
  end

  #
  # CRUD Operation on /invitations/:id
  #
  path "/invitations/{id}" do
    parameter name: "id", in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
    
    # GET /invitations/:id
    get("show invitation") do
      tags "Invitations"
      response(200, "Show invitation") do
        let(:id) { invitation.id }
        run_test!
      end

      response(403, "Cannot see other's invitations") do
        let(:id) { invitation2.id }
        run_test!
      end
    end

    # PATCH /invitations/:id
    patch("update invitation") do
      tags "Invitations"
      consumes "application/json"

      parameter name: :invitation_status, in: :body, schema: {
        type: :object,
        properties: {
          reply_status: { type: :string }
        }
      }

      # Accept invitation
      response(200, "Acceptance successful") do
        let(:id) { invitation2.id }
        let(:invitation_status) { { reply_status: InvitationValidator::ACCEPT_STATUS } }
        run_test!
      end

      response(403, "Cannot accept other's invitations") do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: InvitationValidator::ACCEPT_STATUS } }
        run_test!
      end

      # Decline invitation
      response(200, "Decline successful") do
        let(:id) { invitation2.id }
        let(:invitation_status) { { reply_status: InvitationValidator::DECLINED_STATUS } }
        run_test!
      end

      response(403, "Cannot decline other's invitations") do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: InvitationValidator::DECLINED_STATUS } }
        run_test!
      end

      # Retract invitation
      response(200, "Retraction successful") do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: InvitationValidator::RETRACT_STATUS } }
        run_test!
      end

      response(403, "Cannot retract other's invitations") do
        let(:id) { invitation2.id }
        let(:invitation_status) { { reply_status: InvitationValidator::RETRACT_STATUS } }
        run_test!
      end

      # Invalid status
      response(422, "Invalid request") do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: "Z" } }
        run_test!
      end
    end

    # DELETE /invitations/:id
    delete("Delete invitation") do
      tags "Invitations"
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response(403, "Student cannot delete invitations") do
        let(:id) { invitation2.id }
        run_test!
      end
    end

    delete("Delete invitation") do
      tags "Invitations"
      parameter name: 'Authorization', in: :header, type: :string, required: true
      let(:Authorization) { "Bearer #{ta_token}" }

      response(200, "Delete successful") do
        let(:id) { invitation.id }
        run_test!
      end
    end
  end

  #
  # GET invitations sent by a team 
  #
  path "/invitations/sent_by/team/{team_id}" do
    parameter name: "team_id", in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

    get("Show all invitations sent by team") do
      tags "Invitations"

      response(200, "OK") do
        let(:team_id) { team1.id }
        run_test!
      end
      
      response(403, "Not allowed") do
        let(:team_id) {team2.id}
        run_test!
      end
    end
  end

  #
  # GET invitations sent by a participant
  #
  path "/invitations/sent_by/participant/{participant_id}" do
    parameter name: "participant_id", in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

    get("Show all invitations sent by participant") do
      tags "Invitations"

      response(200, "OK") do
        let(:participant_id) { participant1.id }
        run_test!
      end
      
      response(403, "Not allowed") do
        let(:participant_id) {participant2.id}
        run_test!
      end
    end
  end

  #
  # GET invitations sent to a participant
  #
  path "/invitations/sent_to/{participant_id}" do
    parameter name: "participant_id", in: :path, type: :integer
    parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

    get("Show all invitations sent to participant") do
      tags "Invitations"

      response(200, "OK") do
        let(:participant_id) { participant1.id }
        run_test!
      end
      
      response(403, "Not allowed") do
        let(:participant_id) {participant2.id}
        run_test!
      end
    end
  end
end