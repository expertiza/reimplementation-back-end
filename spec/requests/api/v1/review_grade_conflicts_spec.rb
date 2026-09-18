require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Review Grade Conflicts API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:institution) { Institution.create!(name: 'NCSU') }

  let(:instructor) do
    User.create!(
      name: 'instructor', password_digest: 'pw', full_name: 'Instructor',
      email: 'instructor@example.com', role_id: @roles[:instructor].id,
      institution_id: institution.id
    )
  end

  let(:student1) do
    User.create!(name: 'student1', password_digest: 'pw', role_id: @roles[:student].id,
                 full_name: 'Student One', email: 's1@example.com', institution_id: institution.id)
  end

  let(:student2) do
    User.create!(name: 'student2', password_digest: 'pw', role_id: @roles[:student].id,
                 full_name: 'Student Two', email: 's2@example.com', institution_id: institution.id)
  end

  let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor_id: instructor.id) }

  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  def create_participant(user, asgn)
    AssignmentParticipant.create!(user: user, parent_id: asgn.id, handle: user.name)
  end

  def create_review_grade(participant, grade)
    ReviewGrade.create!(participant: participant, grade_for_reviewer: grade)
  end

  describe 'GET /assignments/:id/review_grades_out_of_bounds' do
    context 'when the assignment does not exist' do
      it 'returns 404' do
        get '/assignments/0/review_grades_out_of_bounds', headers: headers, params: { min: 0, max: 100 }
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Assignment not found')
      end
    end

    context 'when there are no review grades' do
      it 'returns conflict_count of 0' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 0, max: 10 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(0)
      end
    end

    context 'when all grades are within the new scale' do
      before do
        ap1 = create_participant(student1, assignment)
        ap2 = create_participant(student2, assignment)
        create_review_grade(ap1, 5.0)
        create_review_grade(ap2, 8.0)
      end

      it 'returns conflict_count of 0' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 0, max: 10 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(0)
      end
    end

    context 'when a grade exceeds the new max' do
      before do
        ap1 = create_participant(student1, assignment)
        ap2 = create_participant(student2, assignment)
        create_review_grade(ap1, 5.0)   # within 0–4
        create_review_grade(ap2, 5.0)   # exceeds max of 4
      end

      it 'counts grades above the new max as conflicts' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 0, max: 4 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(2)
      end
    end

    context 'when a grade is below the new min' do
      before do
        ap1 = create_participant(student1, assignment)
        create_review_grade(ap1, 1.0)
      end

      it 'counts grades below the new min as conflicts' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 2, max: 10 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(1)
      end
    end

    context 'when grades straddle both min and max violations' do
      before do
        ap1 = create_participant(student1, assignment)
        ap2 = create_participant(student2, assignment)
        create_review_grade(ap1, 1.0)   # below min of 2
        create_review_grade(ap2, 9.0)   # above max of 8
      end

      it 'counts both as conflicts' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 2, max: 8 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(2)
      end
    end

    context 'when only max is provided' do
      before do
        ap1 = create_participant(student1, assignment)
        create_review_grade(ap1, 95.0)
      end

      it 'only checks against max' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { max: 90 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(1)
      end
    end

    context 'when only min is provided' do
      before do
        ap1 = create_participant(student1, assignment)
        create_review_grade(ap1, 2.0)
      end

      it 'only checks against min' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 5 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(1)
      end
    end

    context 'when a participant has no review grade' do
      before do
        create_participant(student1, assignment)
        # no ReviewGrade record created
      end

      it 'ignores participants without grades' do
        get "/assignments/#{assignment.id}/review_grades_out_of_bounds",
            headers: headers, params: { min: 0, max: 10 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['conflict_count']).to eq(0)
      end
    end
  end
end
