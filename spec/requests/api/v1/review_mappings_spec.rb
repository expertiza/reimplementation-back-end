require 'rails_helper'
require 'swagger_helper'
require 'json_web_token'

# This spec file tests the ReviewMappingsController API endpoints
# It includes tests for both calibration review creation and reviewer selection
RSpec.describe "Api::V1::ReviewMappings", type: :request do
  # Create role hierarchy before all tests to ensure proper authorization
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # Create an instructor user for authentication
  # This user will be used to test endpoints that require instructor privileges
  let(:instructor) do
    User.create!(
      name: "instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  # Generate JWT token for authentication
  # This token will be included in the Authorization header for authenticated requests
  let(:token) { JsonWebToken.encode({id: instructor.id}) }
  let(:Authorization) { "Bearer #{token}" }

  # Test the index endpoint (placeholder for future implementation)
  describe "GET /index" do
    pending "add some examples (or delete) #{__FILE__}"
  end

  # Tests for the add_calibration endpoint
  # This endpoint creates a calibration review mapping between a team and an assignment
  path '/api/v1/review_mappings/add_calibration' do
    post 'Creates a calibration review mapping' do
      tags 'Review Mappings'
      security [bearerAuth: []] # Requires JWT authentication
      consumes 'application/json'
      produces 'application/json'
      
      # Define the expected request parameters in Swagger format
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

      # Test successful calibration review creation
      response '201', 'calibration review mapping created' do
        # Create test data
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

        # Verify the response contains expected data
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Calibration review mapping created successfully')
          expect(data['review_mapping']).to be_present
          expect(data['response_url']).to be_present
        end
      end

      # Test unauthorized access (missing/invalid token)
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

      # Test invalid request parameters
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

  # Tests for the select_reviewer endpoint
  # This endpoint selects a contributor for review mapping and stores it in the session
  path '/api/v1/review_mappings/select_reviewer' do
    get 'Select a reviewer' do
      tags 'Review Mappings'
      description 'Select a contributor for review mapping'
      produces 'application/json'
      # Define the query parameter for contributor selection
      parameter name: :contributor_id, in: :query, type: :integer, required: true

      # Test successful contributor selection
      response '200', 'Contributor selected successfully' do
        let(:contributor_id) { assignment_team.id }

        run_test! do
          # Verify the response status and session storage
          expect(response).to have_http_status(:ok)
          expect(session[:contributor]).to eq(assignment_team)
        end
      end

      # Test missing contributor_id parameter
      response '400', 'Bad Request - Missing contributor_id' do
        let(:contributor_id) { nil }

        run_test! do
          # Verify error response
          expect(response).to have_http_status(:bad_request)
          expect(json_response['error']).to eq('Contributor ID is required')
        end
      end

      # Test non-existent contributor
      response '404', 'Contributor not found' do
        let(:contributor_id) { 99999 }

        run_test! do
          # Verify not found response
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # Test suite for POST /api/v1/review_mappings/add_reviewer
  describe 'POST /api/v1/review_mappings/add_reviewer' do
    context 'when the request is valid' do
      before { post '/api/v1/review_mappings/add_reviewer', params: valid_params }

      it 'creates a new review mapping' do
        expect(response).to have_http_status(:created)
        expect(json['reviewer_id']).to eq(user.id)
        expect(json['reviewee_id']).to eq(team.id)
        expect(json['assignment_id']).to eq(assignment.id)
      end
    end

    context 'when the user does not exist' do
      before do
        invalid_params = valid_params.merge(user: { name: 'nonexistent_user' })
        post '/api/v1/review_mappings/add_reviewer', params: invalid_params
      end

      it 'returns an error message' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to match(/User 'nonexistent_user' not found/)
      end
    end

    context 'when attempting self-review' do
      before do
        # Add user to the team to create self-review scenario
        create(:teams_user, team: team, user: user)
        post '/api/v1/review_mappings/add_reviewer', params: valid_params
      end

      it 'returns an error message' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to match(/You cannot assign this student to review their own artifact/)
      end
    end

    context 'when reviewer is already assigned' do
      before do
        # Create an existing review mapping
        create(:review_mapping, 
               reviewer: user, 
               reviewee: team, 
               assignment: assignment)
        post '/api/v1/review_mappings/add_reviewer', params: valid_params
      end

      it 'returns an error message' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to match(/The reviewer, '#{user.name}', is already assigned to this contributor/)
      end
    end

    context 'when topic_id is provided' do
      let(:topic) { create(:topic, assignment: assignment) }
      
      before do
        params_with_topic = valid_params.merge(topic_id: topic.id)
        post '/api/v1/review_mappings/add_reviewer', params: params_with_topic
      end

      it 'creates a review mapping and signs up for topic' do
        expect(response).to have_http_status(:created)
        expect(SignedUpTeam.exists?(team_id: team.id, topic_id: topic.id)).to be true
      end
    end
  end

  private

  # Helper method to parse JSON response body
  def json_response
    JSON.parse(response.body)
  end
end
