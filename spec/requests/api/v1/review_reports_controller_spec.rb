require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Review Reports API', type: :request do
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

  let(:reviewer_user) do
    User.create!(
      name: 'reviewer', password_digest: 'pw', full_name: 'Reviewer',
      email: 'reviewer@example.com', role_id: @roles[:student].id,
      institution_id: institution.id
    )
  end

  let(:reviewee_user) do
    User.create!(
      name: 'reviewee', password_digest: 'pw', full_name: 'Reviewee',
      email: 'reviewee@example.com', role_id: @roles[:student].id,
      institution_id: institution.id
    )
  end

  let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor_id: instructor.id) }

  let(:reviewee_team) do
    AssignmentTeam.create!(name: 'Reviewee Team', parent_id: assignment.id)
  end

  let(:reviewer_participant) do
    AssignmentParticipant.create!(user: reviewer_user, parent_id: assignment.id, handle: 'reviewer')
  end

  let(:review_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewee_team.id
    )
  end

  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  describe 'PATCH /review_reports/:id' do
    context 'when the review map does not exist' do
      it 'returns 404' do
        patch '/review_reports/0', headers: headers,
              params: { assignedGrade: 80, instructorComment: 'Good' }.to_json
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Review mapping not found')
      end
    end

    context 'when saving a grade for the first time' do
      it 'creates a ReviewGrade and returns 200' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 85.0, instructorComment: 'Well done' }.to_json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['grade_for_reviewer']).to eq(85.0)
        expect(body['comment_for_reviewer']).to eq('Well done')
        expect(body['participant_id']).to eq(reviewer_participant.id)
      end

      it 'persists the grade in the database' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 90.0, instructorComment: '' }.to_json
        rg = ReviewGrade.find_by(participant_id: reviewer_participant.id)
        expect(rg).not_to be_nil
        expect(rg.grade_for_reviewer).to eq(90.0)
      end

      it 'records grader_id as the current instructor' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 70.0, instructorComment: '' }.to_json
        rg = ReviewGrade.find_by(participant_id: reviewer_participant.id)
        expect(rg.grader_id).to eq(instructor.id)
      end

      it 'does not set review_graded_at (column removed)' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 70.0, instructorComment: '' }.to_json
        rg = ReviewGrade.find_by(participant_id: reviewer_participant.id)
        expect(rg).not_to respond_to(:review_graded_at)
      end
    end

    context 'when updating an existing grade' do
      before do
        ReviewGrade.create!(
          participant_id: reviewer_participant.id,
          grade_for_reviewer: 50.0,
          comment_for_reviewer: 'Old comment',
          grader_id: instructor.id
        )
      end

      it 'updates the grade and returns 200' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 75.0, instructorComment: 'Revised' }.to_json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['grade_for_reviewer']).to eq(75.0)
        expect(body['comment_for_reviewer']).to eq('Revised')
      end

      it 'does not create a duplicate ReviewGrade record' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 60.0, instructorComment: '' }.to_json
        count = ReviewGrade.where(participant_id: reviewer_participant.id).count
        expect(count).to eq(1)
      end
    end

    context 'when grade is blank (clearing a grade)' do
      it 'saves nil as grade_for_reviewer' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: '', instructorComment: '' }.to_json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['grade_for_reviewer']).to be_nil
      end
    end

    context 'response payload' do
      it 'does not include review_graded_at' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 80.0, instructorComment: 'ok' }.to_json
        body = JSON.parse(response.body)
        expect(body.keys).not_to include('review_graded_at')
      end

      it 'includes participant_id, grade_for_reviewer, comment_for_reviewer' do
        patch "/review_reports/#{review_map.id}", headers: headers,
              params: { assignedGrade: 80.0, instructorComment: 'ok' }.to_json
        body = JSON.parse(response.body)
        expect(body.keys).to include('participant_id', 'grade_for_reviewer', 'comment_for_reviewer')
      end
    end
  end
end
