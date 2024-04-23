require 'swagger_helper'

RSpec.describe 'Submitted Content API', type: :request do

  path '/api/v1/submitted_content/submit_hyperlink' do

    post('submit_hyperlink submitted_content') do
      tags 'SubmittedContent'      
      consumes 'application/json'
      parameter name: :submission, in: :body, schema: {
        type: :object,
        properties: {
          submission: { type: :string },
          id: { type: :integer }
        },
        required: ['submission', 'id']
      }

      response '422', 'You or your teammate(s) have already submitted the same hyperlink' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:team_hyperlinks) { create_list(:hyperlink, 2, team: team) }
        let(:submission) { team_hyperlinks.first }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return(team_hyperlinks)
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { message: 'You or your teammate(s) have already submitted the same hyperlink.' }, status: :unprocessable_entity)
          post '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 422 status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the error message' do
          expect(json['message']).to eq('You or your teammate(s) have already submitted the same hyperlink.')
        end
      end

      response '200', 'Hyperlink submitted successfully' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:submission) { 'New Hyperlink' }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return([])
          allow_any_instance_of(Team).to receive(:submit_hyperlink)
          allow(SubmissionRecord).to receive(:create)
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { message: 'The link has been successfully submitted.' }, status: :ok)
          post '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 200 status code' do
          expect(response).to have_http_status(:ok)
        end
      end

      response '422', 'Invalid URL or URI' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:submission) { 'Invalid Hyperlink' }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return([])
          allow_any_instance_of(Team).to receive(:submit_hyperlink).and_raise(StandardError, 'Invalid URL or URI')
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { error: 'The URL or URI is invalid. Reason: Invalid URL or URI' }, status: :unprocessable_entity)
          post '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 422 status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the error message' do
          expect(json['error']).to eq('The URL or URI is invalid')
        end
      end
    end
    
    get('submit_hyperlink submitted_content') do
      tags 'SubmittedContent'      
      consumes 'application/json'
      parameter name: :submission, in: :body, schema: {
        type: :object,
        properties: {
          submission: { type: :string },
          id: { type: :integer }
        },
        required: ['submission', 'id']
      }

      response '422', 'You or your teammate(s) have already submitted the same hyperlink' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:team_hyperlinks) { create_list(:hyperlink, 2, team: team) }
        let(:submission) { team_hyperlinks.first }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return(team_hyperlinks)
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { message: 'You or your teammate(s) have already submitted the same hyperlink.' }, status: :unprocessable_entity)
          get '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 422 status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the error message' do
          expect(json['message']).to eq('You or your teammate(s) have already submitted the same hyperlink.')
        end
      end

      response '200', 'Hyperlink submitted successfully' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:submission) { 'New Hyperlink' }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return([])
          allow_any_instance_of(Team).to receive(:submit_hyperlink)
          allow(SubmissionRecord).to receive(:create)
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { message: 'The link has been successfully submitted.' }, status: :ok)
          get '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 200 status code' do
          expect(response).to have_http_status(:ok)
        end
      end

      response '422', 'Invalid URL or URI' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:submission) { 'Invalid Hyperlink' }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive_message_chain(:team, :hyperlinks).and_return([])
          allow_any_instance_of(Team).to receive(:submit_hyperlink).and_raise(StandardError, 'Invalid URL or URI')
          allow_any_instance_of(SubmittedContentController).to receive(:render).and_return(json: { error: 'The URL or URI is invalid. Reason: Invalid URL or URI' }, status: :unprocessable_entity)
          get '/submit_hyperlink', params: { id: participant.id, submission: submission }, as: :json
        end

        it 'returns a 422 status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the error message' do
          expect(json['error']).to eq('The URL or URI is invalid')
        end
      end
    end
  end

  path '/api/v1/submitted_content' do
    let(:role) { Role.create(name: 'Student', parent_id: nil, default_page_id: nil) }

    let(:student) {
      User.create(name: 'student 1', email: 'student@test.com', full_name: 'Student Test', password: 'student', role: :role) 
    }

    let(:assignment) { Assignment.create(id: 1) }

    let(:team) { Team.create(id: 1)}

    let(:submission_record1) {
      SubmissionRecord.create(
        type: 'file',
        content: 'Base64',
        operation: nil,
        team_id: :team,
        user: :student.to_s,
        assignment_id: :assignment
    ) }
    # Get /api/v1/submitted_content, returns list of all submitted record.
    get('list all submitted record') do
      tags 'SubmittedContent'
      produces 'application/json'
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.body.size).to eq(1)
        end
      end
    end
    
    # Post /api/v1/submitted_content, for creating new row.
    post('create a submitted record') do
      tags 'SubmittedContent'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :valid_params, in: :body, schema: {
        type: :object,
        properties: {
          type: { type: :string },
          content: { type: :string },
          operation: { type: :string },
          team_id: { type: :integer },
          user: { type: :string },
          assignment_id: { type: :integer }
        },
        required: %w[content operation team_id user assignment_id]
      }

      # valid parameters for test
      let(:valid_params) do 
        {
          content: 'unknown',
          operation: 'serious',
          team_id: 1,
          user: 'student test',
          assignment_id: 1
        }
      end
      
      # invalid parameters for test
      let(:invalid_params) do 
        {
          content: 'unknown',
          operation: 'serious',
          team_id: 1,
          user: nil,  # invalid parameters
          assignment_id: 1
        }
      end
      
      # API response with valid parameters giving 201 status code.
      response(201, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.body).to include('"type":"test"')
        end
      end
      # Testing Server Error for the endpoint.
      response(422, 'unprocessable entity') do
        let(:valid_params) do
          SubmissionRecord.create(invalid_questionnaire_params)
        end
        run_test!
      end
    end
  end

  path '/api/v1/submitted_content/{id}' do

    # Get a specific submission record based on id.
    get('show a submitted record.') do
      tags 'SubmittedContent'
      produces 'application/json'
      # URL parameters.
      parameter name: 'id', in: :path, type: :string, description: 'id'
      # Get the submission record with specific id.
      response(200, 'successful') do
        let(:id) { '1' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.body).to include('"type":"test"')
        end
      end
      # Testing Not Found 404 Error.
      response(404, 'not_found') do
        let(:id) { 'invalid' }  # Using invalid Id type.
        run_test! do
          expect(response.body).to include("Couldn't find")
        end
      end
    end
  end
end
