# frozen_string_literal: true
require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'Submission Records API', type: :request do
  let(:valid_headers) { { "Authorization" => "Bearer valid_token" } }
  let(:invalid_headers) { { "Authorization" => "Bearer invalid_token" } }

  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:student) do
    User.create!(
      name: 'StudentA',
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "studenta@example.com",
      )
  end

  let(:instructor) do
    User.create!(
      name: "Instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'Test Assignment',
      instructor_id: instructor.id
    )
  end

  let!(:team) do
    Team.create!(
      name: 'Team A',
      assignment: assignment,
      users: [student],
      parent_id: 1
    )
  end

  let!(:submission_record) do
    SubmissionRecord.create!(
      team_id: team.id,
      assignment_id: assignment.id,
      user: student,
      operation: "submit",
      content: "Test submission"
    )
  end

  let(:token) { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  path '/submission_records/{id}' do
    get 'Retrieve a Submission Record' do
      tags 'Submission Records'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Submission Record ID'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Bearer Token'

      response '200', 'submission record found' do
        let(:id) { submission_record.id }
        run_test!
      end

      response '404', 'submission record not found' do
        let(:id) { 9999999 }
        run_test!
      end

      response '500', 'internal server error' do
        before do
          allow(SubmissionRecord).to receive(:find).and_raise(StandardError)
        end
        let(:id) { submission_record.id }
        run_test!
      end
    end
  end

  path '/submission_records' do
    post 'Create a Submission Record' do
      tags 'Submission Records'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :submission_record, in: :body, schema: {
        type: :object,
        properties: {
          team_id: { type: :integer },
          assignment_id: { type: :integer },
          user_id: { type: :integer },
          operation: { type: :string },
          content: { type: :string }
        }
      }
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Bearer Token'

      response '201', 'submission record created' do
        let(:submission_record) do
          {
            team_id: team.id,
            assignment_id: assignment.id,
            user_id: student.id,
            operation: "submit",
            content: "New submission"
          }
        end
        run_test!
      end

      response '400', 'bad request - missing parameters' do
        let(:submission_record) { { operation: "submit" } } # Missing required fields
        run_test!
      end
    end
  end

  path '/submission_records/{id}' do
    delete 'Delete a Submission Record' do
      tags 'Submission Records'
      parameter name: :id, in: :path, type: :integer, required: true, description: 'Submission Record ID'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Bearer Token'

      response '204', 'submission record deleted' do
        let(:id) { submission_record.id }
        run_test!
      end

      response '404', 'submission record not found' do
        let(:id) { 9999999 }
        run_test!
      end

      response '403', 'forbidden - student cannot delete' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode({ id: other_student.id })}" }
        let(:id) { submission_record.id }
        run_test!
      end

      response '401', 'unauthorized - invalid token' do
        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { submission_record.id }
        run_test!
      end

      response '503', 'catch all' do
        before do
          allow(SubmissionRecord).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)
        end
        let(:id) { submission_record.id }
        run_test!
      end
    end
  end
end
