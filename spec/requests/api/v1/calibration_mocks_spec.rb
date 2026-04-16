# spec/requests/api/v1/calibration_mocks_spec.rb

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration Mocks', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode({ id: user.id })
    { 'Authorization' => "Bearer #{token}" }
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
      course: Course.create!(name: 'C1', instructor: instructor, institution: @institution, directory_path: 'c1_dir'),
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

  describe 'POST /assignments/:assignment_id/calibration_response_maps (MOCK SUBMISSION)' do
    it 'automatically adds a mock hyperlink to the team if it is missing' do
      headers = auth_headers_for(instructor)
      
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers

      expect(response).to have_http_status(:created)
      
      # Check the team in database
      team = AssignmentTeam.last
      expect(team.submitted_hyperlinks).to include('https://github.com/expertiza/reimplementation')
    end
  end

  describe 'POST /assignments/:assignment_id/calibration_response_maps/:id/begin (MOCK REVIEW)' do
    let!(:questionnaire) do
      Questionnaire.create!(
        name: "Review_#{Time.now.to_i}_#{rand(1000)}",
        instructor_id: instructor.id,
        min_question_score: 0,
        max_question_score: 5,
        questionnaire_type: 'ReviewQuestionnaire'
      )
    end
    let!(:item) do
      Item.create!(
        txt: 'Q1',
        weight: 1,
        seq: 1,
        questionnaire_id: questionnaire.id,
        question_type: 'ScaleItem',
        break_before: true
      )
    end
    # Ensure AssignmentQuestionnaire is created so the mock can find the rubric
    let!(:aq) { AssignmentQuestionnaire.create!(assignment_id: assignment.id, questionnaire_id: questionnaire.id) }

    it 'automatically creates a completed response with answers when begin is called' do
      headers = auth_headers_for(instructor)
      
      # 1. Create the map
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
      map_id = JSON.parse(response.body)['response_map']['id']

      # 2. Call begin (gold-standard response + 3 mock peer reviewers × 1 scored item)
      expect {
        post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/begin", headers: headers
      }.to change(Response, :count).by(4).and change(Answer, :count).by(4)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['redirect_to']).to eq("/assignments/edit/#{assignment.id}/calibration/#{map_id}")
      expect(json['review_status']).to eq('Completed')

      cal_map = ReviewResponseMap.find(map_id)
      gold_resp = Response.find_by!(map_id: map_id)
      expect(gold_resp.is_submitted).to be true
      expect(gold_resp.additional_comment).to include('MOCK GOLD STANDARD')

      gold_ans = gold_resp.scores.find_by!(item_id: item.id)
      expect(gold_ans.answer).to eq(5)
      expect(gold_ans.comments).to include('Predefined score for Q1')

      peer_maps = ReviewResponseMap.where(
        reviewed_object_id: assignment.id,
        reviewee_id: cal_map.reviewee_id,
        for_calibration: false
      )
      expect(peer_maps.count).to eq(3)
    end
  end
end
