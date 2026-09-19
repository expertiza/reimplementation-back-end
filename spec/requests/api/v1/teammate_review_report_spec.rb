require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Teammate Review Report', type: :request do
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
    User.create!(name: 'student1', password_digest: 'pw', full_name: 'Student One',
                 email: 's1@example.com', role_id: @roles[:student].id, institution_id: institution.id)
  end

  let(:student2) do
    User.create!(name: 'student2', password_digest: 'pw', full_name: 'Student Two',
                 email: 's2@example.com', role_id: @roles[:student].id, institution_id: institution.id)
  end

  let(:student3) do
    User.create!(name: 'student3', password_digest: 'pw', full_name: 'Student Three',
                 email: 's3@example.com', role_id: @roles[:student].id, institution_id: institution.id)
  end

  let(:assignment) { Assignment.create!(name: 'Team Project', instructor_id: instructor.id) }

  let(:ap1) { AssignmentParticipant.create!(user: student1, parent_id: assignment.id, handle: 'student1') }
  let(:ap2) { AssignmentParticipant.create!(user: student2, parent_id: assignment.id, handle: 'student2') }
  let(:ap3) { AssignmentParticipant.create!(user: student3, parent_id: assignment.id, handle: 'student3') }

  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  def generate_report(assignment_id = assignment.id)
    post '/reports/generate_report',
         headers: headers,
         params: { assignment_id: assignment_id, type: 'teammate_review_response_map' }.to_json
  end

  def create_teammate_map(reviewer_ap, reviewee_ap)
    TeammateReviewResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id: reviewer_ap.id,
      reviewee_id: reviewee_ap.id
    )
  end

  def submit_response(map, submitted: true)
    Response.create!(map_id: map.id, is_submitted: submitted, updated_at: Time.current)
  end

  # -----------------------------------------------------------------------
  # Basic routing / error cases
  # -----------------------------------------------------------------------

  describe 'POST /reports/generate_report with type teammate_review_response_map' do
    context 'when the assignment does not exist' do
      it 'returns 404' do
        generate_report(0)
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Assignment not found')
      end
    end

    context 'when there are no teammate review maps' do
      it 'returns 200 with an empty reviews array' do
        generate_report
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['reviews']).to eq([])
      end
    end

    context 'response envelope' do
      it 'includes type, assignment_id, and assignment_name' do
        generate_report
        body = JSON.parse(response.body)
        expect(body['type']).to eq('teammate_review_response_map')
        expect(body['assignment_id']).to eq(assignment.id)
        expect(body['assignment_name']).to eq(assignment.name)
      end
    end
  end

  # -----------------------------------------------------------------------
  # Review rows shape
  # -----------------------------------------------------------------------

  describe 'review row structure' do
    before do
      map = create_teammate_map(ap1, ap2)
      submit_response(map, submitted: true)
    end

    it 'returns a review row for the map' do
      generate_report
      body = JSON.parse(response.body)
      expect(body['reviews'].size).to eq(1)
    end

    it 'includes reviewer id and user name' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['reviewer']['id']).to eq(ap1.id)
      expect(review['reviewer']['user']['name']).to eq(student1.name)
    end

    it 'includes reviewee id and user name' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['reviewee']['id']).to eq(ap2.id)
      expect(review['reviewee']['user']['name']).to eq(student2.name)
    end

    it 'marks submitted as true when a submitted response exists' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['submitted']).to be true
    end

    it 'includes last_reviewed_at as an ISO8601 string' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['last_reviewed_at']).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end

  # -----------------------------------------------------------------------
  # Submitted vs unsubmitted
  # -----------------------------------------------------------------------

  describe 'submitted flag' do
    context 'when only an unsubmitted response exists' do
      before do
        map = create_teammate_map(ap1, ap2)
        submit_response(map, submitted: false)
      end

      it 'marks submitted as false' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['submitted']).to be false
      end

      it 'sets last_reviewed_at to nil' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['last_reviewed_at']).to be_nil
      end
    end

    context 'when no response exists at all' do
      before { create_teammate_map(ap1, ap2) }

      it 'marks submitted as false' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['submitted']).to be false
      end

      it 'sets last_reviewed_at to nil' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['last_reviewed_at']).to be_nil
      end
    end
  end

  # -----------------------------------------------------------------------
  # Team name
  # -----------------------------------------------------------------------

  describe 'team_name in review row' do
    context 'when the reviewer is on a team' do
      before do
        team = AssignmentTeam.create!(name: 'Alpha Team', parent_id: assignment.id)
        TeamsParticipant.create!(team: team, user: student1, participant: ap1)
        create_teammate_map(ap1, ap2)
      end

      it 'returns the team name' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['team_name']).to eq('Alpha Team')
      end
    end

    context 'when the reviewer is not on a team' do
      before { create_teammate_map(ap1, ap2) }

      it 'returns nil for team_name' do
        generate_report
        review = JSON.parse(response.body)['reviews'].first
        expect(review['team_name']).to be_nil
      end
    end
  end

  # -----------------------------------------------------------------------
  # Multiple reviewers / reviewees
  # -----------------------------------------------------------------------

  describe 'multiple review maps' do
    before do
      create_teammate_map(ap1, ap2)
      create_teammate_map(ap2, ap1)
      create_teammate_map(ap1, ap3)
    end

    it 'returns one row per TeammateReviewResponseMap' do
      generate_report
      body = JSON.parse(response.body)
      expect(body['reviews'].size).to eq(3)
    end

    it 'includes all reviewer ids' do
      generate_report
      reviewer_ids = JSON.parse(response.body)['reviews'].map { |r| r['reviewer']['id'] }
      expect(reviewer_ids).to include(ap1.id, ap2.id)
    end
  end

  # -----------------------------------------------------------------------
  # Scores / responses nested payload
  # -----------------------------------------------------------------------

  describe 'nested responses in review row' do
    let(:questionnaire) do
      Questionnaire.create!(name: 'TRQ', instructor_id: instructor.id, min_question_score: 0, max_question_score: 5)
    end

    before do
      map = create_teammate_map(ap1, ap2)
      resp = Response.create!(map_id: map.id, is_submitted: true, additional_comment: 'Great work')
      item = questionnaire.items.create!(txt: 'Collaboration', seq: 1, question_type: 'Scale', weight: 1, break_before: true)
      Answer.create!(response: resp, item: item, answer: 4, comments: 'Good')
    end

    it 'includes responses with is_submitted' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['responses'].first['is_submitted']).to be true
    end

    it 'includes additional_comment in response' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      expect(review['responses'].first['additional_comment']).to eq('Great work')
    end

    it 'includes nested scores with answer and comments' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      score = review['responses'].first['scores'].first
      expect(score['answer']).to eq(4)
      expect(score['comments']).to eq('Good')
    end

    it 'includes item txt in the score' do
      generate_report
      review = JSON.parse(response.body)['reviews'].first
      item = review['responses'].first['scores'].first['item']
      expect(item['txt']).to eq('Collaboration')
    end
  end

  # -----------------------------------------------------------------------
  # Partial completion — reviewer submits for some reviewees but not all
  # -----------------------------------------------------------------------

  describe 'partial completion' do
    before do
      map_a = create_teammate_map(ap1, ap2)
      map_b = create_teammate_map(ap1, ap3)
      submit_response(map_a, submitted: true)
      # map_b intentionally has no response
    end

    it 'returns submitted: true for the completed map' do
      generate_report
      reviews = JSON.parse(response.body)['reviews']
      row = reviews.find { |r| r['reviewer']['id'] == ap1.id && r['reviewee']['id'] == ap2.id }
      expect(row['submitted']).to be true
    end

    it 'returns submitted: false for the incomplete map' do
      generate_report
      reviews = JSON.parse(response.body)['reviews']
      row = reviews.find { |r| r['reviewer']['id'] == ap1.id && r['reviewee']['id'] == ap3.id }
      expect(row['submitted']).to be false
    end

    it 'returns last_reviewed_at nil for the incomplete map' do
      generate_report
      reviews = JSON.parse(response.body)['reviews']
      row = reviews.find { |r| r['reviewer']['id'] == ap1.id && r['reviewee']['id'] == ap3.id }
      expect(row['last_reviewed_at']).to be_nil
    end
  end

  # -----------------------------------------------------------------------
  # Only maps for this assignment are returned
  # -----------------------------------------------------------------------

  describe 'assignment scoping' do
    let(:other_assignment) { Assignment.create!(name: 'Other', instructor_id: instructor.id) }

    before do
      other_ap1 = AssignmentParticipant.create!(user: student1, parent_id: other_assignment.id, handle: 'x')
      other_ap2 = AssignmentParticipant.create!(user: student2, parent_id: other_assignment.id, handle: 'y')
      # Map for the other assignment — should not appear
      TeammateReviewResponseMap.create!(
        reviewed_object_id: other_assignment.id,
        reviewer_id: other_ap1.id,
        reviewee_id: other_ap2.id
      )
      # Map for this assignment — should appear
      create_teammate_map(ap1, ap2)
    end

    it 'only returns maps belonging to the requested assignment' do
      generate_report
      body = JSON.parse(response.body)
      expect(body['reviews'].size).to eq(1)
      expect(body['reviews'].first['reviewer']['id']).to eq(ap1.id)
    end
  end
end
