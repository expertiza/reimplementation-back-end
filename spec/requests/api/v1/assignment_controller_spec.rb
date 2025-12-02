# spec/requests/assignment_controller_spec.rb

require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Assignments API', type: :request do
  ##########################################################################
  # Ensure we have a Role with id=2 for the "admin" user
  ##########################################################################
  before(:all) do
    # If your create_roles_hierarchy doesn't create a role with ID=2,
    # we explicitly create it here so 'role_id: 2' is valid.
    Role.create!(id: 2, name: 'admin') unless Role.exists?(2)
  end

  before do
    @roles = create_roles_hierarchy
  end

  let!(:institution) { Institution.create!(id: 100, name: 'NCSU') }

  let!(:user) do
    User.create!(
      id: 1,
      name: "admin",
      full_name: "admin",
      email: "admin@gmail.com",
      password_digest: "admin",
      role_id: 2,          # Must exist in DB
      institution_id: institution.id
    )
  end

  let!(:prof) do
    Instructor.create!(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      institution: institution
    )
  end

  # Create two assignments so the "GET /assignments" test expects 2
  let!(:assignment1) { Assignment.create!(name: 'Test Assignment 1', instructor_id: prof.id) }
  let!(:assignment2) { Assignment.create!(name: 'Test Assignment 2', instructor_id: prof.id) }

  # For any route referencing "assignment.id", we'll use assignment1.
  let(:assignment) { assignment1 }

  let!(:course) do
    create(:course,
           id: 1,
           name: 'ECE517',
           instructor: prof,
           institution: institution
    )
  end

  let(:token) { JsonWebToken.encode({ id: prof.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:questionnaire) do
    Questionnaire.create!(
      name: "Review Rubric",
      instructor: prof,
      private: false,
      min_question_score: 0,
      max_question_score: 10,
      questionnaire_type: "ReviewQuestionnaire"
    )
  end

  # -------------------------------------------------------------------------
  # GET /assignments  (Get assignments)
  # -------------------------------------------------------------------------
  path '/assignments' do
    get 'Get assignments' do
      tags "Get All Assignments"
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'assignment successfully' do
        run_test! do
          assignments_json = JSON.parse(response.body)
          # Expect 2 assignments: assignment1 and assignment2
          expect(assignments_json.size).to eq(2)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{id} (Show assignment)
  # -------------------------------------------------------------------------
  path '/assignments/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID'

    get 'Show assignment details with rubrics and due dates' do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'assignment found' do
        let(:id) { assignment.id }

        before do
          assignment.update!(vary_by_round: true)
          AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1)
          AssignmentDueDate.create!(
            parent: assignment,
            due_at: Time.zone.now + 1.day,
            deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
            submission_allowed_id: 1,
            review_allowed_id: 1,
            round: 1
          )
        end

        run_test! do
          data = JSON.parse(response.body)

          expect(data['id']).to eq(assignment.id)
          expect(data['assignment_questionnaires'].first['questionnaire']['id']).to eq(questionnaire.id)
          expect(data['due_dates'].length).to eq(1)
          expect(data['num_review_rounds']).to eq(1)
          expect(data['varying_rubrics_by_round']).to eq(true)
        end
      end

      response '404', 'assignment not found' do
        let(:id) { 999 }

        run_test! do
          data = JSON.parse(response.body)
          expect(response).to have_http_status(:not_found)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # POST /assignments/{assignment_id}/add_participant/{user_id}
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/add_participant/{user_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'user_id', in: :path, type: :string

    post 'Adds a participant to an assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'participant added successfully' do
        let(:user_id)       { user.id }         # "admin" user
        let(:assignment_id) { assignment.id }    # assignment1

        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 999 }
        let(:user_id)       { user.id }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # DELETE /assignments/{assignment_id}/remove_participant/{user_id}
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/remove_participant/{user_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'user_id', in: :path, type: :string

    delete 'Removes a participant from an assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'participant removed successfully' do
        let(:user_id)       { user.id }
        let(:assignment_id) { assignment.id }

        before do
          assignment.add_participant(user.id)
        end

        run_test! do
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment or user not found' do
        let(:assignment_id) { 999 }
        let(:user_id)       { user.id }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # PATCH /assignments/{assignment_id}/assign_course/{course_id}
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/assign_course/{course_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'course_id', in: :path, type: :string

    patch 'Make course_id of assignment null' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'course_id assigned successfully' do
        let(:course_id)     { course.id }
        let(:assignment_id) { assignment.id }

        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['course_id']).to eq(course.id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 999 }
        let(:course_id)     { course.id }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # PATCH /assignments/{assignment_id}/remove_assignment_from_course
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/remove_assignment_from_course' do
    patch 'Removes assignment from course' do
      tags 'Assignments'
      produces 'application/json'
      parameter name: :assignment_id, in: :path, type: :integer, required: true
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'assignment removed from course' do
        let(:assignment_id) { assignment.id }
        let(:course_id)     { course.id }

        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['course_id']).to be_nil
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 999 }
        let(:course_id)     { 1 }

        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['error']).to eq('Assignment not found')
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # POST /assignments/{assignment_id}/copy_assignment
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/copy_assignment' do
    parameter name: 'assignment_id', in: :path, type: :string

    post 'Copy an existing assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response '200', 'assignment copied successfully' do
        let(:assignment_id) { assignment.id }

        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 999 }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # DELETE /assignments/{id}
  # -------------------------------------------------------------------------
  path '/assignments/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID'

    delete('Delete an assignment') do
      tags 'Assignments'
      produces 'application/json'
      consumes 'application/json'
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Assignment deleted successfully!')
        end
      end

      response(404, 'Assignment not found') do
        let(:id) { 999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{assignment_id}/has_topics
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/has_topics' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has topics') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{assignment_id}/team_assignment
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/team_assignment' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment is a team assignment') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{assignment_id}/valid_num_review/{review_type}
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/valid_num_review/{review_type}' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'
    parameter name: 'review_type', in: :path, type: :string, description: 'Review Type'

    get('Check if an assignment has a valid number of reviews') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment_id) { assignment.id }
        let(:review_type)   { 'review' }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 }
        let(:review_type)   { 'some_type' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{assignment_id}/has_teams
  # -------------------------------------------------------------------------
  path '/assignments/{assignment_id}/has_teams' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has teams') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /assignments/{id}/show_assignment_details
  # -------------------------------------------------------------------------
  path '/assignments/{id}/show_assignment_details' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID'

    get('Retrieve assignment details') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:id)       { assignment.id }
        let(:topic_id) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(data['id']).to eq(assignment.id)
          expect(data['name']).to eq(assignment.name)
          expect(data['has_badge']).to eq(assignment.has_badge?)
          expect(data['pair_programming_enabled']).to eq(assignment.pair_programming_enabled?)
          expect(data['is_calibrated']).to eq(assignment.is_calibrated?)
          expect(data['staggered_and_no_topic']).to eq(assignment.staggered_and_no_topic?(topic_id))
        end
      end

      response(404, 'Assignment not found') do
        let(:id) { 999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response).to have_http_status(:not_found)
          expect(data['error']).to eq('Assignment not found')
        end
        
      end
    end
  end
end
