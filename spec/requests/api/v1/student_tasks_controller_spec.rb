# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      username: "Instructor",
      password: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:studenta) do
    User.create!(
      username: "studenta",
      password: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "testuser@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({id: studenta.id}) }
  let(:Authorization) { "Bearer #{token}" }

  # -------------------------------------------------------------------------
  # /student_tasks/list
  # -------------------------------------------------------------------------
  path '/student_tasks/list' do
    get 'student tasks list' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string

      # Just a basic "200" test
      response '200', 'authorized request has success response' do
        run_test!
      end

      # The "proper JSON schema" test
      response '200', 'authorized request has proper JSON schema' do
        let!(:setup_tasks) do
          institution = Institution.create!(name: 'NCSU Test')
          course = Course.create!(
            name: "CSC 517",
            directory_path: "csc517",
            instructor: instructor,
            institution: institution
          )
          assignment = Assignment.create!(
            name: "Sample Assignment",
            instructor: instructor,
            course: course
          )
          DueDate.create!(
            parent: assignment,
            due_at: 7.days.from_now,
            deadline_name: 'Submission',
            deadline_type_id: 1,
            submission_allowed_id: 3,
            review_allowed_id: 3
          )
          5.times do |i|
            AssignmentParticipant.create!(
              user_id: studenta.id,
              parent_id: assignment.id,
              handle: "#{studenta.name}_#{i}",
              permission_granted: [true, false].sample
            )
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.size).to eq(5)

          data.each do |task|
            expect(task['assignment']).to be_a(String)
            expect(task['current_stage']).to be_a(String)
            expect(task['stage_deadline']).to be_a(String)
            expect(task['permission_granted']).to be_in([true, false])
          end
        end
      end

      # Unauthorized test
      response '401', 'unauthorized request has error response' do
        let(:'Authorization') { "Bearer " }
        run_test!
      end
    end
  end

  # -------------------------------------------------------------------------
  # /student_tasks/show/{id}  — consolidated from two overlapping path blocks
  # -------------------------------------------------------------------------
  path '/student_tasks/show/{id}' do
    get 'Retrieve a specific student task by participant ID' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns full task payload with due dates and stage info' do
        let!(:show_participant) do
          institution = Institution.create!(name: 'NCSU Show Test')
          course = Course.create!(name: 'CSC 517 Show', directory_path: 'csc517_show', instructor: instructor, institution: institution)
          assignment = Assignment.create!(name: 'Timeline Assignment', instructor: instructor, course: course)
          DueDate.create!(parent: assignment, due_at: 7.days.from_now, deadline_name: 'Submission', deadline_type_id: 1, submission_allowed_id: 3, review_allowed_id: 3)
          AssignmentParticipant.create!(user_id: studenta.id, parent_id: assignment.id, handle: studenta.name, permission_granted: true)
        end
        let(:id) { show_participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']).to eq('Timeline Assignment')
          expect(data['current_stage']).to be_a(String)
          expect(data['stage_deadline']).to be_a(String)
          expect(data['permission_granted']).to be true
        end
      end

      response '404', 'participant not found — returns error message' do
        let(:id) { -1 }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Participant not found')
        end
      end

      response '403', 'student accessing another participant task — returns error message' do
        let!(:other_user) do
          User.create!(
            name: 'otherstudent',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Other Student',
            email: 'other@example.com'
          )
        end
        let!(:other_assignment) { Assignment.create!(name: 'Other Assignment', instructor: instructor) }
        let!(:other_participant) do
          AssignmentParticipant.create!(
            user_id: other_user.id,
            parent_id: other_assignment.id,
            handle: other_user.name
          )
        end
        let(:id) { other_participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq("Unauthorized access to participant's task")
        end
      end

      response '401', 'missing or invalid token — returns Not Authorized' do
        let(:'Authorization') { 'Bearer ' }
        let(:id) { 1 }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eql('Not Authorized')
        end
      end
    end
  end

end
