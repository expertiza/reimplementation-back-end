require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Invitations API', type: :request do
  let(:user1) { create :user, name: "rohitgeddam" }
  let(:user2) { create :user, name: "superman" }
  let(:invalid_user) { build :user, name: "INVALID"}
  let(:assignment) { create(:assignment) }

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
        let(:invitation) { {to_id: user1.id, from_id: user2.id, assignment_id: assignment.id} }
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
        let(:invitation) { {to_id: invalid_user.id, from_id: user2.id, assignment_id: assignment.id} }
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
        let(:invitation) { {to_id: user1.id, from_id: invalid_user.id, assignment_id: assignment.id} }
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
        let(:invitation) { {to_id: user1.id, from_id: user2.id, assignment_id: nil} }
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
        let(:invitation) { { to_id: user1.id, from_id: user2.id, assignment_id: assignment.id, reply_status: "I" } }
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
end
