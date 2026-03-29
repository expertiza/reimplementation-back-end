require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Assignments API Serialization', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.find_or_create_by!(name: 'Test Institution Serialization')
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
      name: 'Test Assignment',
      instructor_id: instructor.id,
      directory_path: 'test_assignment',
      is_calibrated: true,
      has_badge: true,
      staggered_deadline: false
    )
  end

  let!(:questionnaire) do
    Questionnaire.create!(
      name: 'Review Rubric',
      instructor_id: instructor.id,
      questionnaire_type: 'ReviewQuestionnaire',
      min_question_score: 0,
      max_question_score: 5
    )
  end

  let!(:aq) do
    AssignmentQuestionnaire.create!(
      assignment_id: assignment.id,
      questionnaire_id: questionnaire.id,
      used_in_round: 1
    )
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode({ id: user.id })
    { 'Authorization' => "Bearer #{token}" }
  end

  describe 'GET /assignments/:id' do
    it 'returns the expected JSON structure with nested associations and virtual fields' do
      get "/assignments/#{assignment.id}", headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json).to include('id', 'name', 'directory_path', 'is_calibrated', 'has_badge', 'staggered_deadline')
      expect(json['is_calibrated']).to be true
      expect(json['has_badge']).to be true
      
      expect(json).to include('assignment_questionnaires')
      expect(json['assignment_questionnaires'].first).to include('questionnaire')
      expect(json['assignment_questionnaires'].first['questionnaire']).to include('id', 'name')
      
      expect(json).to include('due_dates')
      expect(json).to include('num_review_rounds')
      expect(json).to include('varying_rubrics_by_round')
      expect(json).to include('has_teams')
      expect(json).to include('has_topics')
      expect(json).to include('show_teammate_review')
      expect(json).to include('is_pair_programming')
      expect(json).to include('maximum_number_of_reviews_per_submission')
      expect(json).to include('review_strategy')
      expect(json).to include('review_rubric_varies_by_topic')
      expect(json).to include('review_rubric_varies_by_role')
      expect(json).to include('has_max_review_limit')
      expect(json).to include('set_allowed_number_of_reviews_per_reviewer')
      expect(json).to include('set_required_number_of_reviews_per_reviewer')
      expect(json).to include('is_review_anonymous')
      expect(json).to include('is_review_done_by_teams')
      expect(json).to include('allow_self_reviews')
      expect(json).to include('reviews_visible_to_other_reviewers')
      expect(json).to include('use_signup_deadline')
      expect(json).to include('use_drop_topic_deadline')
      expect(json).to include('use_team_formation_deadline')
    end
  end

  describe 'POST /assignments' do
    it 'creates an assignment and returns mapped virtual fields' do
      params = {
        assignment: {
          name: 'New Assignment',
          instructor_id: instructor.id,
          show_teammate_review: true, # Frontend name
          is_pair_programming: true,   # Frontend name
          show_template_review: true,  # Virtual attribute
          maximum_number_of_reviews_per_submission: 5, # New attribute
          review_strategy: 'rs',
          review_rubric_varies_by_topic: true,
          review_rubric_varies_by_role: true,
          has_max_review_limit: true,
          set_allowed_number_of_reviews_per_reviewer: 3,
          set_required_number_of_reviews_per_reviewer: 2,
          is_review_anonymous: true,
          is_review_done_by_teams: true,
          allow_self_reviews: true,
          reviews_visible_to_other_reviewers: true,
          review_rubric_varies_by_round: true,
          allow_tag_prompts: true,
          use_signup_deadline: true,
          use_drop_topic_deadline: true,
          use_team_formation_deadline: true,
          weights: [1, 2, 3],
          notification_limits: [10, 20],
          use_date_updater: [true, false],
          submission_allowed: [true, true],
          review_allowed: [true, false],
          teammate_allowed: [false, false],
          metareview_allowed: [true, true],
          reminder: [1, 2],
          review_topic_threshold: 5,
          days_between_submissions: 7,
          late_policy_id: 1,
          is_penalty_calculated: true,
          calculate_penalty: true,
          apply_late_policy: true
        }
      }
      post '/assignments', params: params, headers: auth_headers_for(instructor)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('New Assignment')
      expect(json['show_teammate_review']).to be true
      expect(json['is_pair_programming']).to be true
      expect(json['maximum_number_of_reviews_per_submission']).to eq(5)
      expect(json['review_strategy']).to eq('rs')
      expect(json['review_rubric_varies_by_round']).to be true
      expect(json['allow_tag_prompts']).to be true
      expect(json['use_signup_deadline']).to be true
      expect(json['use_drop_topic_deadline']).to be true
      expect(json['use_team_formation_deadline']).to be true
      expect(json['review_rubric_varies_by_topic']).to be true
      expect(json['review_rubric_varies_by_role']).to be true
      expect(json['has_max_review_limit']).to be true
      expect(json['set_allowed_number_of_reviews_per_reviewer']).to eq(3)
      expect(json['set_required_number_of_reviews_per_reviewer']).to eq(2)
      expect(json['is_review_anonymous']).to be true
      expect(json['is_review_done_by_teams']).to be true
      expect(json['allow_self_reviews']).to be true
      expect(json['reviews_visible_to_other_reviewers']).to be true
      expect(json['weights']).to eq([1, 2, 3])
      expect(json['notification_limits']).to eq([10, 20])
      expect(json['review_topic_threshold']).to eq(5)
      expect(json['late_policy_id']).to eq(1)
      expect(json['apply_late_policy']).to be true
    end
  end

  describe 'PATCH /assignments/:id' do
    let!(:assignment) { create(:assignment, name: 'Old Name', instructor: instructor) }
    let(:update_params) {
      {
        assignment: {
          name: 'Updated Name',
          is_review_anonymous: false,
          weights: [4, 5],
          review_topic_threshold: 10
        }
      }
    }

    it 'updates the assignment and returns the full JSON structure' do
      patch "/assignments/#{assignment.id}", params: update_params, headers: auth_headers_for(instructor)
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['name']).to eq('Updated Name')
      expect(json['is_review_anonymous']).to be false
      expect(json['weights']).to eq([4, 5])
      expect(json['review_topic_threshold']).to eq(10)
    end
  end
end
