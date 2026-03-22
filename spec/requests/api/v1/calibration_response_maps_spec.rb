# frozen_string_literal: true
require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/calibration_response_maps', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  let(:instructor) do
    User.create!(
      name: 'instructor1',
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor One',
      email: 'instructor1@example.com',
      institution: @institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'A1',
      instructor_id: instructor.id,
      directory_path: 'a1_dir',
      rounds_of_reviews: 1,
      max_team_size: 3
    )
  end

  let(:student) do
    User.create!(
      name: 'student1',
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student One',
      email: 'student1@example.com',
      institution: @institution
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  path '/assignments/{assignment_id}/calibration_response_maps' do
    parameter name: :assignment_id, in: :path, type: :string, description: 'Assignment ID'

    get 'List calibration response maps for the assignment' do
      tags 'Calibration'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Success' do
        let(:assignment_id) { assignment.id }
        run_test!
      end

      response '404', 'Assignment not found' do
        let(:assignment_id) { 'invalid' }
        run_test!
      end
    end

    post 'Create or find calibration participant and response map' do
      tags 'Calibration'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
      parameter name: :calibration_params, in: :body, schema: {
        type: :object,
        properties: {
          username: { type: :string, example: 'student1' }
        },
        required: ['username']
      }

      response '201', 'Created' do
        let(:assignment_id) { assignment.id }
        let(:calibration_params) { { username: student.name } }
        run_test!
      end

      response '404', 'Unknown username' do
        let(:assignment_id) { assignment.id }
        let(:calibration_params) { { username: 'nonexistent' } }
        run_test!
      end

      response '403', 'Forbidden for students' do
        let(:student_token) { JsonWebToken.encode({ id: student.id }) }
        let(:Authorization) { "Bearer #{student_token}" }
        let(:assignment_id) { assignment.id }
        let(:calibration_params) { { username: student.name } }
        run_test!
      end
    end
  end

  path '/assignments/{assignment_id}/calibration_response_maps/{id}/begin' do
    parameter name: :assignment_id, in: :path, type: :string, description: 'Assignment ID'
    parameter name: :id, in: :path, type: :string, description: 'Response Map ID'

    post 'Initiate the calibration review' do
      tags 'Calibration'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Success' do
        let(:assignment_id) { assignment.id }
        let(:id) do
          map = ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: AssignmentParticipant.find_or_create_by!(parent_id: assignment.id, user_id: instructor.id).id,
            reviewee_id: AssignmentParticipant.find_or_create_by!(parent_id: assignment.id, user_id: student.id).id,
            for_calibration: true
          )
          map.id
        end
        run_test!
      end

      response '403', 'Not authorized for this calibration map' do
        let(:other_instructor) do
          User.create!(
            name: 'instructor2',
            password: 'password',
            role_id: @roles[:instructor].id,
            full_name: 'Instructor Two',
            email: 'instructor2@example.com',
            institution: @institution
          )
        end
        let(:other_token) { JsonWebToken.encode({ id: other_instructor.id }) }
        let(:Authorization) { "Bearer #{other_token}" }
        let(:assignment_id) { assignment.id }
        let(:id) do
          map = ResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: AssignmentParticipant.find_or_create_by!(parent_id: assignment.id, user_id: instructor.id).id,
            reviewee_id: AssignmentParticipant.find_or_create_by!(parent_id: assignment.id, user_id: student.id).id,
            for_calibration: true
          )
          map.id
        end
        run_test!
      end
    end
  end
end
