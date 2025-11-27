require 'swagger_helper'
require 'rails_helper'
require 'action_dispatch/http/upload'
require 'json_web_token'
require 'tmpdir'
# Explicitly load dependencies to avoid autoload ordering issues
require Rails.root.join('app/models/application_record')
require Rails.root.join('app/models/user')
require Rails.root.join('app/models/role')
require Rails.root.join('app/models/institution')
require Rails.root.join('app/models/participant')
require Rails.root.join('app/models/assignment_participant')
require Rails.root.join('app/models/team')
require Rails.root.join('app/models/assignment_team')
require Rails.root.join('app/models/teams_participant')
require Rails.root.join('app/helpers/file_helper')
require Rails.root.join('app/helpers/metric_helper')
require Rails.root.join('app/helpers/submitted_content_helper')
require Rails.root.join('app/models/assignment')
require Rails.root.join('app/controllers/concerns/jwt_token')
require Rails.root.join('app/controllers/concerns/authorization')
require Rails.root.join('app/controllers/application_controller')
require Rails.root.join('app/controllers/submitted_content_controller')

RSpec.describe 'Submitted Content API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
    Assignment
  end

  def assignment_participant_class
    Object.const_get('AssignmentParticipant')
  rescue NameError
    require Rails.root.join('app/models/application_record')
    require Rails.root.join('app/models/user')
    require Rails.root.join('app/models/role')
    require Rails.root.join('app/models/institution')
    require Rails.root.join('app/models/participant')
    require Rails.root.join('app/models/assignment_participant')
    require Rails.root.join('app/models/team')
    require Rails.root.join('app/models/assignment_team')
    require Rails.root.join('app/models/teams_participant')
    require Rails.root.join('app/helpers/file_helper')
    require Rails.root.join('app/helpers/metric_helper')
    require Rails.root.join('app/helpers/submitted_content_helper')
    require Rails.root.join('app/models/assignment')
    require Rails.root.join('app/controllers/concerns/jwt_token')
    require Rails.root.join('app/controllers/application_controller')
    require Rails.root.join('app/controllers/concerns/authorization')
    require Rails.root.join('app/controllers/submitted_content_controller')
    Object.const_get('AssignmentParticipant')
  end

  def assignment_class
    Object.const_get('Assignment')
  rescue NameError
    load Rails.root.join('app/models/assignment.rb')
    Object.const_get('Assignment')
  end

  let(:institution) { Institution.create!(name: 'NC State') }

  let(:instructor) do
    User.create!(
      name: 'profa',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Prof A',
      email: 'testuser@example.com',
      mru_directory_path: '/home/testuser',
      institution_id: institution.id
    )
  end

  let(:student) do
    User.create!(
      full_name: 'Student Member',
      name: 'student_member',
      email: 'studentmember@example.com',
      password_digest: 'password',
      role_id: @roles[:student].id,
      institution_id: institution.id
    )
  end

  let(:assignment) { assignment_class.create!(name: 'Assignment 1', instructor_id: instructor.id, max_team_size: 3) }

  let(:team) do
    AssignmentTeam.create!(
      parent_id: assignment.id,
      name: 'Team 1',
      user_id: student.id
    )
  end

  let(:participant) do
    assignment_participant_class.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let(:teams_participant) do
    TeamsParticipant.create!(
      team_id: team.id,
      user_id: student.id,
      participant_id: participant.id
    )
  end
  
  let(:Authorization) { auth_headers_student['Authorization'] }
  let(:auth_headers_instructor) { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: instructor.id)}" } }
  let(:auth_headers_student) { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: student.id)}" } }

  def json
    JSON.parse(response.body)
  end

  # helper to create submission records
  def create_submission_record(attrs = {})
    SubmissionRecord.create!({
      record_type: 'file',
      content: '/path/to/file.txt',
      operation: 'Submit File',
      team_id: team.id,
      user: student.name,
      assignment_id: assignment.id
    }.merge(attrs))
  end

  path '/submitted_content' do
    get('list all submission records') do
      tags 'SubmittedContent'
      produces 'application/json'

      response(200, 'successful') do
        before do
          create_submission_record
          create_submission_record(content: '/path/to/file2.txt')
        end

        after do |example|
          if response && response.body.present?
            example.metadata[:response][:content] = {
              'application/json' => { example: JSON.parse(response.body, symbolize_names: true) }
            }
          end
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(2)
        end
      end
    end

    post('create a submission record') do
      tags 'SubmittedContent'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :submitted_content, in: :body, schema: {
        type: :object,
        properties: {
          submitted_content: {
            type: :object,
            properties: {
              record_type: { type: :string },
              content: { type: :string },
              operation: { type: :string },
              team_id: { type: :integer },
              user: { type: :string },
              assignment_id: { type: :integer }
            },
            required: %w[content team_id user assignment_id]
          }
        }
      }

      response(201, 'created') do
        let(:submitted_content) do
          {
            submitted_content: {
              content: 'http://example.com',
              operation: 'Submit Hyperlink',
              team_id: team.id,
              user: student.name,
              assignment_id: assignment.id
            }
          }
        end

        after do |example|
          if response && response.body.present?
            example.metadata[:response][:content] = {
              'application/json' => { example: JSON.parse(response.body, symbolize_names: true) }
            }
          end
        end

        run_test! do
          expect(response).to have_http_status(:created)
          parsed = json
          expect(parsed['record_type']).to eq('hyperlink')
          expect(parsed['content']).to eq('http://example.com')
        end
      end

      response(422, 'unprocessable entity') do
        let(:submitted_content) do
          {
            submitted_content: {
              content: 'test content'
              # missing required keys intentionally
            }
          }
        end

        run_test! do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  path '/submitted_content/{id}' do
    get('show a submission record') do
      tags 'SubmittedContent'
      produces 'application/json'
      parameter name: 'id', in: :path, type: :string, description: 'id'

      response(200, 'successful') do
        let(:submission_record) { create_submission_record }
        let(:id) { submission_record.id }

        after do |example|
          if response && response.body.present?
            example.metadata[:response][:content] = {
              'application/json' => { example: JSON.parse(response.body, symbolize_names: true) }
            }
          end
        end

        run_test! do
          expect(response).to have_http_status(:ok)
          parsed = json
          expect(parsed['id']).to eq(submission_record.id)
        end
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }

        run_test! do
          expect(response).to have_http_status(:not_found)
          parsed = json
          expect(parsed['error']).to include("Couldn't find SubmissionRecord")
        end
      end
    end
  end

  path '/submitted_content/submit_hyperlink' do
    shared_examples 'hyperlink submission' do |method|
      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(team)
        allow(participant).to receive(:user).and_return(student)
        allow(participant).to receive(:assignment).and_return(assignment)
      end

      context 'with valid submission' do
        let(:id) { participant.id }
        let(:submission) { 'http://valid-link.com' }

        before do
          allow(team).to receive(:hyperlinks).and_return([])
          allow(team).to receive(:submit_hyperlink)
        end

        it 'returns success' do
          send(method, '/submitted_content/submit_hyperlink',
               params: { id: id, submission: submission },
               headers: auth_headers_student)

          expect(response).to have_http_status(:ok)
          parsed = json
          expect(parsed['message']).to eq('The link has been successfully submitted.')
        end
      end

      context 'with blank submission' do
        let(:id) { participant.id }
        let(:submission) { '' }

        it 'returns bad request' do
          send(method, '/submitted_content/submit_hyperlink',
               params: { id: id, submission: submission },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('cannot be blank')
        end
      end

      context 'with duplicate hyperlink' do
        let(:id) { participant.id }
        let(:submission) { 'http://duplicate-link.com' }

        before do
          allow(team).to receive(:hyperlinks).and_return([submission])
        end

        it 'returns conflict' do
          send(method, '/submitted_content/submit_hyperlink',
               params: { id: id, submission: submission },
               headers: auth_headers_student)

          expect(response).to have_http_status(:conflict)
          parsed = json
          expect(parsed['error']).to include('already submitted the same hyperlink')
        end
      end

      context 'with invalid URL' do
        let(:id) { participant.id }
        let(:submission) { 'invalid-url' }

        before do
          allow(team).to receive(:hyperlinks).and_return([])
          allow(team).to receive(:submit_hyperlink).and_raise(StandardError, 'Invalid URL format')
        end

        it 'returns bad request with error' do
          send(method, '/submitted_content/submit_hyperlink',
               params: { id: id, submission: submission },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('The URL or URI is invalid')
        end
      end
    end

    describe 'POST' do
      it_behaves_like 'hyperlink submission', :post
    end

    describe 'GET' do
      it_behaves_like 'hyperlink submission', :get
    end
  end

  path '/submitted_content/remove_hyperlink' do
    shared_examples 'hyperlink removal' do |method|
      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(team)
        allow(participant).to receive(:user).and_return(student)
        allow(participant).to receive(:assignment).and_return(assignment)
      end

      context 'with valid hyperlink index' do
        let(:id) { participant.id }
        let(:chk_links) { 0 }
        let(:hyperlink) { 'http://link-to-remove.com' }

        before do
          allow(team).to receive(:hyperlinks).and_return([hyperlink])
          allow(team).to receive(:remove_hyperlink)
        end

        it 'returns no content' do
          send(method, '/submitted_content/remove_hyperlink',
               params: { id: id, chk_links: chk_links },
               headers: auth_headers_student)

          expect(response).to have_http_status(:no_content)
        end
      end

      context 'with invalid hyperlink index' do
        let(:id) { participant.id }
        let(:chk_links) { 10 }

        before do
          allow(team).to receive(:hyperlinks).and_return([])
        end

        it 'returns not found' do
          send(method, '/submitted_content/remove_hyperlink',
               params: { id: id, chk_links: chk_links },
               headers: auth_headers_student)

          expect(response).to have_http_status(:not_found)
          parsed = json
          expect(parsed['error']).to include('Hyperlink not found')
        end
      end

      context 'with removal error' do
        let(:id) { participant.id }
        let(:chk_links) { 0 }
        let(:hyperlink) { 'http://link-with-error.com' }

        before do
          allow(team).to receive(:hyperlinks).and_return([hyperlink])
          allow(team).to receive(:remove_hyperlink).and_raise(StandardError, 'Database error')
        end

        it 'returns internal server error' do
          send(method, '/submitted_content/remove_hyperlink',
               params: { id: id, chk_links: chk_links },
               headers: auth_headers_student)

          expect(response).to have_http_status(:internal_server_error)
          parsed = json
          expect(parsed['error']).to include('Failed to remove hyperlink')
        end
      end
    end

    describe 'POST' do
      it_behaves_like 'hyperlink removal', :post
    end

    describe 'GET' do
      it_behaves_like 'hyperlink removal', :get
    end
  end

  path '/submitted_content/submit_file' do
    shared_examples 'file submission' do |method|
      let(:team_directory) { Dir.mktmpdir }

      after do
        FileUtils.remove_entry(team_directory) if team_directory && Dir.exist?(team_directory)
      end

      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(team)
        allow(participant).to receive(:user).and_return(student)
        allow(participant).to receive(:assignment).and_return(assignment)
        allow(participant).to receive(:team_path).and_return(team_directory)
        allow_any_instance_of(SubmittedContentController)
          .to receive(:ensure_participant_team).and_return(true)
        allow_any_instance_of(SubmittedContentController)
          .to receive(:participant_team).and_return(team)
        allow(team).to receive(:set_student_directory_num)
        allow(team).to receive(:path).and_return('/test/path')
      end

      context 'without file' do
        let(:id) { participant.id }

        it 'returns bad request' do
          send(method, '/submitted_content/submit_file',
               params: { id: id },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('No file provided')
        end
      end

      context 'with oversized file' do
        let(:id) { participant.id }
        let(:uploaded_file) do
          # Create a tempfile with block syntax
          temp_file = nil
          Tempfile.create(['test', '.txt']) do |file|
            file.write('a' * 6.megabytes)
            file.rewind
            temp_file = ActionDispatch::Http::UploadedFile.new(
              tempfile: file,
              filename: 'large_file.txt',
              type: 'text/plain'
            )
          end
          temp_file
        end

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:is_file_small_enough).and_return(false)
        end

        it 'returns bad request for size limit' do
          send(method, '/submitted_content/submit_file',
               params: { id: id, uploaded_file: uploaded_file },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('File size must be smaller than')
        end
      end

      context 'with invalid extension' do
        let(:id) { participant.id }
        let(:uploaded_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new('test content'),
            'application/x-msdownload',
            original_filename: 'test.exe'
          )
        end

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:is_file_small_enough).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:check_extension_integrity).and_return(false)
        end

        it 'returns bad request for invalid extension' do
          send(method, '/submitted_content/submit_file',
               params: { id: id, uploaded_file: uploaded_file },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('File extension not allowed')
        end
      end

      context 'with valid file' do
        let(:id) { participant.id }
        let(:uploaded_file) do
          file = Tempfile.new(['test', '.txt'])
          file.write('test content')
          file.rewind
          ActionDispatch::Http::UploadedFile.new(
            tempfile: file,
            filename: 'test.txt',
            type: 'text/plain'
          )
        end

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:is_file_small_enough).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:check_extension_integrity).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:create_submission_record_for).and_return(true)
        end

        it 'returns success' do
          send(method, '/submitted_content/submit_file',
              params: { id: id, uploaded_file: uploaded_file, current_folder: { name: '' } },
              headers: auth_headers_student)

          expect(response).to have_http_status(:created)
          parsed = json
          expect(parsed['message']).to eq('The file has been submitted successfully.')
        end
      end

      context 'with zip file and unzip flag' do
        let(:id) { participant.id }
        let(:uploaded_file) do
          file = Tempfile.new(['test', '.zip'])
          file.binmode
          file.write('PK')  # Minimal zip file signature
          file.write("\x03\x04" + "\x00" * 18)  # Basic zip header
          file.rewind
          ActionDispatch::Http::UploadedFile.new(
            tempfile: file,
            filename: 'test.zip',
            type: 'application/zip'
          )
        end

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:is_file_small_enough).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:check_extension_integrity).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:file_type).and_return('zip')
          allow(SubmittedContentHelper).to receive(:unzip_file).and_return({ message: 'Unzipped successfully' })
          allow_any_instance_of(SubmittedContentController)
            .to receive(:create_submission_record_for).and_return(true)
        end

        it 'unzips the file when requested' do
          expect(SubmittedContentHelper).to receive(:unzip_file)

          send(method, '/submitted_content/submit_file',
              params: { id: id, uploaded_file: uploaded_file, unzip: true, current_folder: { name: '' } },
              headers: auth_headers_student)

          expect(response).to have_http_status(:created)
        end
      end
    end

    describe 'POST' do
      it_behaves_like 'file submission', :post
    end

    describe 'GET' do
      it_behaves_like 'file submission', :get
    end
  end

  path '/submitted_content/folder_action' do
    shared_examples 'folder actions' do |method|
      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(team)
        allow_any_instance_of(SubmittedContentController)
          .to receive(:ensure_participant_team).and_return(true)
      end

      context 'without action specified' do
        let(:id) { participant.id }

        it 'returns bad request' do
          send(method, '/submitted_content/folder_action',
               params: { id: id },
               headers: auth_headers_student)

          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('No folder action specified')
        end
      end

      context 'with delete action' do
        let(:id) { participant.id }
        let(:faction) { { delete: 'true' } }

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:delete_selected_files).and_return(nil)
        end

        it 'calls delete_selected_files' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:delete_selected_files)

          send(method, '/submitted_content/folder_action',
               params: { id: id, faction: faction },
               headers: auth_headers_student)
        end
      end

      context 'with rename action' do
        let(:id) { participant.id }
        let(:faction) { { rename: 'new_name.txt' } }

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:rename_selected_file).and_return(nil)
        end

        it 'calls rename_selected_file' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:rename_selected_file)

          send(method, '/submitted_content/folder_action',
               params: { id: id, faction: faction },
               headers: auth_headers_student)
        end
      end

      context 'with move action' do
        let(:id) { participant.id }
        let(:faction) { { move: '/new/location' } }

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:move_selected_file).and_return(nil)
        end

        it 'calls move_selected_file' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:move_selected_file)

          send(method, '/submitted_content/folder_action',
               params: { id: id, faction: faction },
               headers: auth_headers_student)
        end
      end

      context 'with copy action' do
        let(:id) { participant.id }
        let(:faction) { { copy: '/copy/location' } }

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:copy_selected_file).and_return(nil)
        end

        it 'calls copy_selected_file' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:copy_selected_file)

          send(method, '/submitted_content/folder_action',
               params: { id: id, faction: faction },
               headers: auth_headers_student)
        end
      end

      context 'with create action' do
        let(:id) { participant.id }
        let(:faction) { { create: 'new_folder' } }

        before do
          allow_any_instance_of(SubmittedContentController)
            .to receive(:create_new_folder).and_return(nil)
        end

        it 'calls create_new_folder' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:create_new_folder)

          send(method, '/submitted_content/folder_action',
               params: { id: id, faction: faction },
               headers: auth_headers_student)
        end
      end
    end

    describe 'POST' do
      it_behaves_like 'folder actions', :post
    end

    describe 'GET' do
      it_behaves_like 'folder actions', :get
    end
  end

  path '/submitted_content/download' do
    get('download file') do
      tags 'SubmittedContent'
      produces 'application/octet-stream'
      parameter name: :current_folder, in: :query, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        },
        required: [:name]
      }
      parameter name: :download, in: :query, type: :string, required: true
      parameter name: :id, in: :query, type: :string, required: true

      before do
        # Ensure participant and team are created before the test runs
        participant
        team
        teams_participant
      end

      response(400, 'folder name is nil') do
        let(:current_folder) { { name: '' } }
        let(:download) { 'test.txt' }
        let(:id) { participant.id }

        run_test! do
          parsed = json
          expect(parsed['error']).to include('Folder name is required')
        end
      end

      response(400, 'file name is nil') do
        let(:id) { participant.id }
        let(:current_folder) { { name: '/test' } }
        let(:download) { '' }

        run_test! do
          parsed = json
          expect(parsed['error']).to include('File name is required')
        end
      end

      response(400, 'cannot send whole folder') do
        let(:id) { participant.id }
        let(:current_folder) { { name: '/test' } }
        let(:download) { 'folder_name' }

        before do
          allow(File).to receive(:directory?).and_return(true)
        end

        run_test! do
          parsed = json
          expect(parsed['error']).to include('Cannot download a directory')
        end
      end

      response(404, 'file does not exist') do
        let(:id) { participant.id }
        let(:current_folder) { { name: '/test' } }
        let(:download) { 'nonexistent.txt' }

        before do
          allow(File).to receive(:directory?).and_return(false)
          allow(File).to receive(:exist?).and_return(false)
        end

        run_test! do
          parsed = json
          expect(parsed['error']).to include('does not exist')
        end
      end

      response(200, 'file downloaded') do
        let(:id) { participant.id }
        let(:current_folder) { { name: '/test' } }
        let(:download) { 'existing.txt' }
        let(:file_path) { File.join('/test', 'existing.txt') }

        before do
          allow(File).to receive(:directory?).and_call_original
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:directory?).with(file_path).and_return(false)
          allow(File).to receive(:exist?).with(file_path).and_return(true)
          allow_any_instance_of(SubmittedContentController)
            .to receive(:send_file).and_return(nil)
        end

        it 'sends the file' do
          expect_any_instance_of(SubmittedContentController)
            .to receive(:send_file).with(file_path, disposition: 'inline')

          get '/submitted_content/download',
              params: { id: id, current_folder: current_folder, download: download },
              headers: auth_headers_student
        end
      end
    end
  end

  path '/submitted_content/list_files' do
    get('list files and hyperlinks') do
      tags 'SubmittedContent'
      produces 'application/json'
      parameter name: :id, in: :query, type: :string, required: true
      parameter name: :folder, in: :query, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        }
      }

      let(:id) { participant.id }
      let(:folder) { { name: '/' } }
      let(:temp_dir) { Dir.mktmpdir }

      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(team)
        allow(participant).to receive(:team_path).and_return(temp_dir)
        allow(team).to receive(:set_student_directory_num)
        allow(team).to receive(:hyperlinks).and_return([])
        FileUtils.mkdir_p(File.join(temp_dir, 'subfolder'))
        File.write(File.join(temp_dir, 'file.txt'), 'content')
      end

      after do
        FileUtils.remove_entry(temp_dir) if temp_dir && Dir.exist?(temp_dir)
      end

      response(200, 'directory listed') do
        run_test! do
          expect(response).to have_http_status(:ok)
          parsed = json
          expect(parsed['current_folder']).to eq('/')
          expect(parsed['files']).to be_an(Array)
          expect(parsed['folders']).to be_an(Array)
          expect(parsed['hyperlinks']).to be_an(Array)
        end
      end

      response(400, 'not a directory') do
        let(:folder) { { name: '/file.txt' } }

        run_test! do
          expect(response).to have_http_status(:bad_request)
          parsed = json
          expect(parsed['error']).to include('not a directory')
        end
      end
    end
  end

  describe 'Error handling' do
    context 'when participant not found' do
      it 'returns 500 (RecordNotFound bubbles)' do
        allow(AssignmentParticipant).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        post '/submitted_content/submit_hyperlink',
             params: { id: 999, submission: 'http://test.com' },
             headers: auth_headers_student

        # controller currently does not rescue set_participant -> RecordNotFound => 500
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when team not found' do
      before do
        allow(AssignmentParticipant).to receive(:find).and_return(participant)
        allow(participant).to receive(:team).and_return(nil)
      end

      it 'returns not found for submit_hyperlink' do
        post '/submitted_content/submit_hyperlink',
             params: { id: participant.id, submission: 'http://test.com' },
             headers: auth_headers_student

        expect(response).to have_http_status(:not_found)
        parsed = json
        expect(parsed['error']).to include('not associated with a team')
      end
    end
  end

  # Minimal happy-path coverage to ensure rswag generation for all routes
  describe 'SubmittedContent happy paths' do
    before do
      allow(AssignmentParticipant).to receive(:find).and_return(participant)
      allow(participant).to receive(:team).and_return(team)
      allow(participant).to receive(:team_path).and_return(Dir.mktmpdir)
      allow(team).to receive(:hyperlinks).and_return([])
      allow(team).to receive(:submit_hyperlink)
      allow(team).to receive(:remove_hyperlink)
      allow(team).to receive(:set_student_directory_num)
      allow(team).to receive(:path).and_return('/tmp')
    end

    it 'lists submission records' do
      create_submission_record
      get '/submitted_content', headers: auth_headers_student
      expect(response).to have_http_status(:ok)
    end

    it 'shows a submission record' do
      rec = create_submission_record
      get "/submitted_content/#{rec.id}", headers: auth_headers_student
      expect(response).to have_http_status(:ok)
    end

    it 'submits a hyperlink (POST)' do
      post '/submitted_content/submit_hyperlink',
           params: { id: participant.id, submission: 'http://example.com' },
           headers: auth_headers_student
      expect(response).to have_http_status(:ok)
    end

    it 'removes a hyperlink (POST)' do
      allow(team).to receive(:hyperlinks).and_return(['http://example.com'])
      post '/submitted_content/remove_hyperlink',
           params: { id: participant.id, chk_links: 0 },
           headers: auth_headers_student
      expect(response).to have_http_status(:no_content)
    end

    it 'submits a file (POST)' do
      tempfile = Tempfile.new(['happy', '.txt'])
      tempfile.write('hi')
      tempfile.rewind
      uploaded = ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: 'happy.txt', type: 'text/plain')
      allow_any_instance_of(SubmittedContentController).to receive(:check_extension_integrity).and_return(true)
      allow_any_instance_of(SubmittedContentController).to receive(:create_submission_record_for).and_return(true)
      post '/submitted_content/submit_file',
           params: { id: participant.id, uploaded_file: uploaded, current_folder: { name: '' } },
           headers: auth_headers_student
      expect(response).to have_http_status(:created)
    ensure
      tempfile&.close!
    end

    it 'performs a folder action (POST)' do
      allow_any_instance_of(SubmittedContentController).to receive(:delete_selected_files).and_return(nil)
      post '/submitted_content/folder_action',
           params: { id: participant.id, faction: { delete: 'true' } },
           headers: auth_headers_student
      expect([200, 204]).to include(response.status)
    end

    it 'downloads a file (GET)' do
      dir = Dir.mktmpdir
      file_path = File.join(dir, 'dl.txt')
      File.write(file_path, 'hi')
      allow(participant).to receive(:team_path).and_return(dir)
      get '/submitted_content/download',
          params: { id: participant.id, current_folder: { name: dir }, download: 'dl.txt' },
          headers: auth_headers_student
      expect(response).to have_http_status(:ok)
    ensure
      FileUtils.remove_entry(dir) if dir && Dir.exist?(dir)
    end

    it 'lists files (GET)' do
      get '/submitted_content/list_files',
          params: { id: participant.id, folder: { name: '/' } },
          headers: auth_headers_student
      expect(response).to have_http_status(:ok)
    end
  end
end
