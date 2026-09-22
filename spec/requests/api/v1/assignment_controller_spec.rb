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
    User.create!(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser"
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

  # instructor_grade_min_score / instructor_grade_max_score
  # -------------------------------------------------------------------------

  describe 'instructor grade scale fields' do
    describe 'GET /assignments/:id (show)' do
      it 'includes instructor_grade_min_score and instructor_grade_max_score in the response' do
        assignment.update!(instructor_grade_min_score: 1, instructor_grade_max_score: 10)
        get "/assignments/#{assignment.id}", headers: { 'Authorization' => Authorization() }
        data = JSON.parse(response.body)
        expect(data['instructor_grade_min_score']).to eq(1)
        expect(data['instructor_grade_max_score']).to eq(10)
      end

      it 'includes assignment_questionnaires with nested questionnaire in the response' do
        questionnaire = Questionnaire.create!(name: 'Review Q', instructor_id: prof.id,
                                             min_question_score: 1, max_question_score: 5)
        questionnaire.items.create!(txt: 'Q1', seq: 1, question_type: 'Scale', weight: 1, break_before: true)
        AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire,
                                        used_in_round: 1, questionnaire_weight: 100)
        get "/assignments/#{assignment.id}", headers: { 'Authorization' => Authorization() }
        data = JSON.parse(response.body)
        aqs = data['assignment_questionnaires']
        expect(aqs).not_to be_empty
        expect(aqs.first['questionnaire']).not_to be_nil
        expect(aqs.first['questionnaire']['id']).to eq(questionnaire.id)
      end
    end

    describe 'PATCH /assignments/:id (update)' do
      it 'saves instructor_grade_min_score and instructor_grade_max_score' do
        patch "/assignments/#{assignment.id}",
              params: { assignment: { instructor_grade_min_score: 0, instructor_grade_max_score: 5 } },
              headers: { 'Authorization' => Authorization() }
        expect(response).to have_http_status(:ok)
        assignment.reload
        expect(assignment.instructor_grade_min_score).to eq(0)
        expect(assignment.instructor_grade_max_score).to eq(5)
      end

      it 'does not raise UnknownAttributeError for permitted params' do
        expect do
          patch "/assignments/#{assignment.id}",
                params: { assignment: { name: 'Updated', instructor_grade_min_score: 1,
                                        instructor_grade_max_score: 10 } },
                headers: { 'Authorization' => Authorization() }
        end.not_to raise_error
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # -------------------------------------------------------------------------
  # PATCH /assignments/{id}  — field persistence for bug-fixed fields
  # -------------------------------------------------------------------------
  describe 'PATCH /assignments/:id' do
    let(:assignment) { Assignment.create!(name: 'Patch Test', instructor_id: prof.id) }

    def patch_assignment(id, body)
      patch "/assignments/#{id}",
            params: { assignment: body }.to_json,
            headers: { 'Content-Type' => 'application/json', 'Authorization' => Authorization }
    end

    # ------------------------------------------------------------------
    # is_penalty_calculated (the real DB column behind apply_late_policy)
    # ------------------------------------------------------------------
    context 'is_penalty_calculated' do
      it 'persists true when sent in the payload' do
        patch_assignment(assignment.id, { is_penalty_calculated: true })
        expect(response).to have_http_status(:ok)
        expect(assignment.reload.is_penalty_calculated).to be true
        expect(JSON.parse(response.body)['is_penalty_calculated']).to be true
      end

      it 'persists false when sent in the payload' do
        assignment.update!(is_penalty_calculated: true)
        patch_assignment(assignment.id, { is_penalty_calculated: false })
        expect(response).to have_http_status(:ok)
        expect(assignment.reload.is_penalty_calculated).to be false
      end

      it 'apply_late_policy (virtual) in payload does not change is_penalty_calculated' do
        # Sending the virtual name alone should be a no-op on the DB column.
        # The frontend now always sends is_penalty_calculated, not apply_late_policy.
        assignment.update!(is_penalty_calculated: false)
        patch_assignment(assignment.id, { apply_late_policy: true })
        expect(assignment.reload.is_penalty_calculated).to be false
      end
    end

    # ------------------------------------------------------------------
    # set_allowed_number_of_reviews_per_reviewer (alias → num_reviews_allowed)
    # ------------------------------------------------------------------
    context 'set_allowed_number_of_reviews_per_reviewer' do
      it 'persists a positive limit' do
        patch_assignment(assignment.id, { set_allowed_number_of_reviews_per_reviewer: 4 })
        expect(response).to have_http_status(:ok)
        expect(assignment.reload.num_reviews_allowed).to eq(4)
        expect(JSON.parse(response.body)['set_allowed_number_of_reviews_per_reviewer']).to eq(4)
      end

      it 'persists zero to clear the limit' do
        assignment.update!(num_reviews_allowed: 5)
        patch_assignment(assignment.id, { set_allowed_number_of_reviews_per_reviewer: 0 })
        expect(response).to have_http_status(:ok)
        expect(assignment.reload.num_reviews_allowed).to eq(0)
      end

      it 'has_max_review_limit (virtual) in payload is accepted without error and is a no-op' do
        patch_assignment(assignment.id, { has_max_review_limit: true })
        expect(response).to have_http_status(:ok)
        # DB column is unchanged
        expect(assignment.reload.num_reviews_allowed).to eq(assignment.num_reviews_allowed)
      end
    end

    # ------------------------------------------------------------------
    # Named deadline due_dates_attributes (drop_topic, team_formation, signup)
    # ------------------------------------------------------------------
    context 'named deadline due_dates_attributes' do
      it 'creates a drop_topic deadline when none exists' do
        due_at = 7.days.from_now
        patch_assignment(assignment.id, {
          due_dates_attributes: [{
            deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
            due_at: due_at.iso8601,
            submission_allowed_id: 3,
            review_allowed_id: 3,
            teammate_review_allowed_id: 3
          }]
        })
        expect(response).to have_http_status(:ok)
        dd = assignment.due_dates.find_by(deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC)
        expect(dd).not_to be_nil
        expect(dd.due_at.to_i).to be_within(2).of(due_at.to_i)
      end

      it 'updates only allowed_ids on an existing named deadline (no due_at change)' do
        original_due_at = 5.days.from_now
        dd = AssignmentDueDate.create!(
          parent: assignment,
          due_at: original_due_at,
          deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
          submission_allowed_id: 3, review_allowed_id: 3, teammate_review_allowed_id: 3
        )

        patch_assignment(assignment.id, {
          due_dates_attributes: [{
            id: dd.id,
            deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
            submission_allowed_id: 1,
            review_allowed_id: 2,
            teammate_review_allowed_id: 1
          }]
        })

        expect(response).to have_http_status(:ok)
        dd.reload
        expect(dd.submission_allowed_id).to eq(1)
        expect(dd.review_allowed_id).to eq(2)
        # due_at is preserved since we omitted it from the payload
        expect(dd.due_at.to_i).to be_within(2).of(original_due_at.to_i)
      end

      it 'creates a team_formation deadline with the correct deadline_name in the response' do
        due_at = 10.days.from_now
        patch_assignment(assignment.id, {
          due_dates_attributes: [{
            deadline_type_id: ExpertizaConstants::DeadlineTypes::TEAM_FORMATION,
            due_at: due_at.iso8601,
            submission_allowed_id: 3,
            review_allowed_id: 3,
            teammate_review_allowed_id: 3
          }]
        })
        expect(response).to have_http_status(:ok)
        due_dates = JSON.parse(response.body)['due_dates']
        tf = due_dates.find { |d| d['deadline_type_id'] == ExpertizaConstants::DeadlineTypes::TEAM_FORMATION }
        expect(tf).not_to be_nil
        expect(tf['deadline_name']).to eq('team_formation')
      end
    end
  end
end
