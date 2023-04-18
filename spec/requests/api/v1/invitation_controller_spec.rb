require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Invitations API', type: :request do
  let(:user1) { create :user }
  let(:user2) { create :user }
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

      response(201, 'Create an invitation') do
        let(:invitation) { {to_id: user1.id, from_id: user2.id, assignment_id: assignment.id} }
        after do |example|
          p example
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
