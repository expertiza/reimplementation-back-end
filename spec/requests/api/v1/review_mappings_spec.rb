require 'rails_helper'
require 'swagger_helper'
require 'json_web_token'

RSpec.describe "Api::V1::ReviewMappings", type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) do
    User.create!(
      name: "instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({id: instructor.id}) }
  let(:Authorization) { "Bearer #{token}" }

  describe "GET /index" do
    pending "add some examples (or delete) #{__FILE__}"
  end

  path '/api/v1/review_mappings/add_calibration' do
    post 'Creates a calibration review mapping' do
      tags 'Review Mappings'
      security [bearerAuth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :calibration, in: :body, schema: {
        type: :object,
        properties: {
          calibration: {
            type: :object,
            properties: {
              assignment_id: { type: :integer, description: 'ID of the assignment' },
              team_id: { type: :integer, description: 'ID of the team' }
            },
            required: ['assignment_id', 'team_id']
          }
        }
      }

      response '201', 'calibration review mapping created' do
        let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor_id: instructor.id) }
        let(:team) { Team.create!(name: 'Test Team', assignment_id: assignment.id) }
        let(:calibration) do
          {
            calibration: {
              assignment_id: assignment.id,
              team_id: team.id
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Calibration review mapping created successfully')
          expect(data['review_mapping']).to be_present
          expect(data['response_url']).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:calibration) do
          {
            calibration: {
              assignment_id: 1,
              team_id: 1
            }
          }
        end
        let(:Authorization) { nil }

        run_test! do |response|
          expect(response.status).to eq(401)
        end
      end

      response '422', 'invalid request' do
        let(:calibration) do
          {
            calibration: {
              assignment_id: nil,
              team_id: nil
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to be_present
        end
      end
    end
  end
end
