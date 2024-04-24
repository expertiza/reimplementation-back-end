require 'swagger_helper'

RSpec.describe 'Submitted Content API', type: :request do
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

  path '/api/v1/submitted_content/submit_hyperlink' do

    post('submit_hyperlink submitted_content') do
      tags 'SubmittedContent'
      consumes 'application/json'
      parameter name: :id, in: :query, type: :string, required: true
      parameter name: :submission, in: :query, type: :string, required: true


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
      parameter name: :id, in: :query, type: :string, required: true
      parameter name: :submission, in: :query, type: :string, required: true

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

  path '/api/v1/submitted_content/remove_hyperlink' do

    get('remove_hyperlink submitted_content') do
      tags 'SubmittedContent'
      consumes 'application/json'
      parameter name: :id, in: :query, type: :integer, required: true
      parameter name: :chk_links, in: :query, type: :integer, required: true

      response '204', 'Hyperlink removed successfully' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:hyperlink_to_delete) { create(:hyperlink, team: team) }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive(:team).and_return(team)
          allow(team.hyperlinks).to receive(:[]).and_return(hyperlink_to_delete)
          allow(team).to receive(:remove_hyperlink)
          allow(SubmissionRecord).to receive(:create)
        end

        let(:id) { participant.id }
        let(:chk_links) { 0 }

        run_test!
      end

      response '422', 'Unprocessable Entity' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:hyperlink_to_delete) { create(:hyperlink, team: team) }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive(:team).and_return(team)
          allow(team.hyperlinks).to receive(:[]).and_return(hyperlink_to_delete)
          allow(team).to receive(:remove_hyperlink).and_raise(StandardError, 'Error deleting hyperlink')
        end

        let(:id) { participant.id }
        let(:chk_links) { 0 } # Assuming the parameter corresponds to the index of the hyperlink to delete

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json['error']).to include('There was an error deleting the hyperlink.')
        end
      end
    end

    post('remove_hyperlink submitted_content') do
      tags 'SubmittedContent'
      consumes 'application/json'
      parameter name: :id, in: :query, type: :integer, required: true
      parameter name: :chk_links, in: :query, type: :integer, required: true


      response '204', 'Hyperlink removed successfully' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:hyperlink_to_delete) { create(:hyperlink, team: team) }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive(:team).and_return(team)
          allow(team.hyperlinks).to receive(:[]).and_return(hyperlink_to_delete)
          allow(team).to receive(:remove_hyperlink)
          allow(SubmissionRecord).to receive(:create)
        end

        let(:id) { participant.id }
        let(:chk_links) { 0 }

        run_test!
      end

      response '422', 'Unprocessable Entity' do
        let(:participant) { create(:assignment_participant) }
        let(:team) { create(:team) }
        let(:hyperlink_to_delete) { create(:hyperlink, team: team) }

        before do
          allow(AssignmentParticipant).to receive(:find).and_return(participant)
          allow(participant).to receive(:team).and_return(team)
          allow(team.hyperlinks).to receive(:[]).and_return(hyperlink_to_delete)
          allow(team).to receive(:remove_hyperlink).and_raise(StandardError, 'Error deleting hyperlink')
        end

        let(:id) { participant.id }
        let(:chk_links) { 0 } # Assuming the parameter corresponds to the index of the hyperlink to delete

        run_test! do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json['error']).to include('There was an error deleting the hyperlink.')
        end
      end
    end
  end

  path '/api/v1/submitted_content/submit_file' do

    post('submit_file submitted_content') do
      tags 'SubmittedContent'
      consumes 'multipart/form-data'
      parameter name: :file, in: :formData, type: :object, schema: {
        type: :object,
        properties: {
          uploaded_file: { type: :string, format: :binary },
        }
      }
      parameter name: :id, in: :query, type: :string, required: true

      response(422, 'There was a problem in performing file operations.') do
        run_test!
      end
      response(409, 'A file already exists in this directory with the same name. Please delete the existing file before copying.') do
        run_test!
      end
      response(404, 'The referenced file does not exist.') do
        run_test!
      end
      response(400, 'A file with this name already exists.') do
        run_test!
      end
      response(204, 'Requested operation has been performed.') do
        run_test!
      end
      response(200, 'Requested operation has been performed.') do
        run_test!
      end

    end
  end

  path '/api/v1/submitted_content/download' do
    get('download submitted_content') do
      tags 'SubmittedContent'
      produces 'application/octet-stream'
      parameter name: 'current_folder[name]', in: :query, type: :string, required: true
      parameter name: :download, in: :query, type: :string, required: true

      response '400', 'Bad request: Folder name is nil or File name is nil' do
        let(:current_folder) { { name: nil } }
        let(:download) { 'test_file.pdf' }

        run_test! do
          expect(json['message']).to eq('Folder_name is nil.')
        end
      end

      response '400', 'Bad request: Cannot send a whole folder' do
        let(:current_folder) { { name: 'test_folder' } }
        let(:download) { 'test_folder' }

        run_test! do
          expect(json['message']).to eq('Cannot send a whole folder.')
        end
      end

      response '404', 'File not found' do
        let(:current_folder) { { name: 'test_folder' } }
        let(:download) { 'nonexistent_file.pdf' }

        run_test! do
          expect(json['message']).to eq('File does not exist.')
        end
      end

      response '200', 'File downloaded' do
        let(:current_folder) { { name: 'test_folder' } }
        let(:download) { 'test_file.txt' }

        run_test!
      end
    end
  end

  path '/api/v1/submitted_content/folder_action' do
    post('folder_action submitted_content') do
      tags 'SubmittedContent'
      consumes 'application/json'
      parameter name: :valid_params, in: :body, schema: {
        type: :object,
        properties: {
          directories: { type: :array, items: { type: :string } },
          chk_files: { type: :integer },
          filenames: { type: :array, items: { type: :string } },
          faction: {
            type: :object, properties: {
            delete: { type: :string },
            rename: { type: :string },
            move: { type: :string },
            copy: { type: :string },
            create: { type: :string }
          },
          required: %w(delete rename move copy create) },
        },
      }
      parameter name: :id, in: :query, type: :integer, required: true

      response(200, 'Action completed successfully.') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(204, 'File has been deleted.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(400, 'A file with this name already exists. Please delete the existing file before copying.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'The referenced file does not exist.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(409, 'A file already exists in this directory with the name') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'There was a problem in file operation.') do
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

    get('folder_action submitted_content') do
      tags 'SubmittedContent'
      consumes 'application/json'
      parameter name: :valid_params, in: :body, schema: {
        type: :object,
        properties: {
          directories: { type: :array, items: { type: :string } },
          chk_files: { type: :integer },
          filenames: { type: :array, items: { type: :string } },
          faction: {
            type: :object, properties: {
            delete: { type: :string },
            rename: { type: :string },
            move: { type: :string },
            copy: { type: :string },
            create: { type: :string }
          },
          required: %w(delete rename move copy create) },
        },
      }
      parameter name: :id, in: :query, type: :integer, required: true

      response(200, 'Action completed successfully.') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(204, 'File has been deleted.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(400, 'A file with this name already exists. Please delete the existing file before copying.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(404, 'The referenced file does not exist.') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(409, 'A file already exists in this directory with the name') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(422, 'There was a problem in file operation.') do

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
