require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Invitations API', type: :request do
  let(:user1) { create :user, name: 'rohitgeddam' }
  let(:user2) { create :user, name: 'superman' }
  let(:invalid_user) { build :user, name: 'INVALID' }
  let(:assignment) { create(:assignment) }
  let(:invitation) { create :invitation, from_user: user1, to_user: user2, assignment: assignment }

  path '/api/v1/invitations' do

    get('list invitations') do
      tags 'Invitations'
      produces 'application/json'

      response(200, 'successful') do

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

      response(201, 'Create an invitation with valid parameters') do
        let(:invitation) { { to_id: user1.id, from_id: user2.id, assignment_id: assignment.id } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Create an invitation with invalid to user parameters') do
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

      response(422, 'Create an invitation with invalid from user parameters') do
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

      response(422, 'Create an invitation with invalid assignment parameters') do
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

      response(422, 'Create an invitation with invalid reply_status parameters') do
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

      response(422, 'Create an invitation with same to user and from user parameters') do
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
      response(200, 'show request with valid invitation id') do
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

    end

    get('show invitation') do
      tags 'Invitations'
      response(404, 'show request with invalid invitation id') do
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
      tags 'Invitation'
      consumes 'application/json'
      parameter name: :invitation_status, in: :body, schema: {
        type: :object,
        properties: {
          reply_status: { type: :string }
        },
        required: %w[]
      }

      response(200, 'Accept invite') do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: Invitation::ACCEPT_STATUS } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(200, 'Reject invite') do
        let(:id) { invitation.id }
        let(:invitation_status) { { reply_status: Invitation::REJECT_STATUS } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Invalid invite action') do
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

      response(404, 'Update status with invalid invitation_id') do
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

      delete('delete invitation with valid invite id') do
        tags 'Invitation'
        response(200, 'successful') do
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
      end

      delete('delete invitation with invalid invite id') do
        tags 'Invitation'
        response(404, 'successful') do
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

  path '/api/v1/invitations/{user_id}/{assignment_id}' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'id of user'
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'id of assignment'

    get('show all invitation with valid user and assignment') do
      tags 'Invitations'
      response(200, 'show all invitations for the user for an assignment') do
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
    end

    get('show invitation with invalid user and assignment') do
      tags 'Invitations'
      response(404, 'show all invitations for the user for an assignment') do
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
    end


    get('show invitation with user and invalid assignment') do
      tags 'Invitations'
      response(404, 'show all invitations for the user for an assignment') do
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
    end

    get('show invitation with invalid user and invalid assignment') do
      tags 'Invitations'
      response(404, 'show all invitations for the user for an assignment') do
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
