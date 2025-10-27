require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Invitations API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:student) {
    User.create(
      name: "studenta",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "student A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:prof) {
    User.create(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: student.id}) }
  let(:Authorization) { "Bearer #{token}" }
  let(:user1) { create :user, name: 'rohitgeddam', role_id: @roles[:student].id }
  let(:user2) { create :user, name: 'superman', role_id: @roles[:student].id }
  let(:invalid_user) { build :user, name: 'INVALID', role_id: nil }
  let(:assignment) { Assignment.create!(id: 1, name: 'Test Assignment', instructor_id: prof.id) }
  let(:participant1) { create :participant, user: user1, parent_id: assignment.id  }
  let(:participant2) { create :participant, user: user2, parent_id: assignment.id   }
  let(:invitation) { Invitation.create!(from_user: user1, to_user: user2, assignment: assignment) }

  path '/api/v1/invitations' do

    get('list invitations') do
      tags 'Invitations'
      produces 'application/json'
      response(200, 'Success') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post('create invitation') do
      tags 'Invitations'
      consumes 'application/json'
      parameter name: :invitation, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: { type: :integer },
          from_id: { type: :integer },
          to_id: { type: :integer },
          reply_status: { type: :string }
        },
        required: %w[assignment_id from_id to_id]
      }

      response(201, 'Create successful') do
        let(:invitation) { { to_id: participant1.id, from_id: participant2.id, assignment_id: assignment.id } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:invitation) { { to_id: invalid_user.id, from_id: user2.id, assignment_id: assignment.id } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:invitation) { { to_id: user1.id, from_id: invalid_user.id, assignment_id: assignment.id } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:invitation) { { to_id: user1.id, from_id: user2.id, assignment_id: nil } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:invitation) { { to_id: user1.id, from_id: user2.id, assignment_id: assignment.id, reply_status: 'I' } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:invitation) { { to_id: user1.id, from_id: user1.id, assignment_id: assignment.id } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/invitations/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the invitation'
    get('show invitation') do
      tags 'Invitations'
      response(200, 'Show invitation') do
        let(:id) { invitation.id }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not found') do
        let(:id) { 'INVALID' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    patch('update invitation') do
      tags 'Invitations'
      consumes 'application/json'
      parameter name: :invitation_status, in: :body, schema: {
        type: :object,
        properties: {
          reply_status: { type: :string }
        },
        required: %w[]
      }

      response(200, 'Update successful') do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: InvitationValidator::ACCEPT_STATUS } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(200, 'Update successful') do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: InvitationValidator::DECLINED_STATUS } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid request') do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: 'Z' } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not found') do
        let(:id) { invitation.id + 10 }
        let(:invitation_status) { { reply_status: 'A' } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      delete('Delete invitation') do
        tags 'Invitations'
        response(204, 'Delete successful') do
          let(:id) { invitation.id }
          run_test!
        end

        response(404, 'Not found') do
          let(:id) { invitation.id + 100 }

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end
      end
    end
  end

  path '/api/v1/invitations/user/{user_id}/assignment/{assignment_id}' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'id of user'
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'id of assignment'
    get('Show all invitation for the given user and assignment') do
      tags 'Invitations'
      response(200, 'Show all invitations for the user for an assignment') do
        let(:user_id) { user1.id }
        let(:assignment_id) { assignment.id }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not found') do
        let(:user_id) { 'INVALID' }
        let(:assignment_id) { assignment.id }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not found') do
        let(:user_id) { user1.id }
        let(:assignment_id) { 'INVALID' }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not found') do
        let(:user_id) { 'INVALID' }
        let(:assignment_id) { 'INVALID' }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
