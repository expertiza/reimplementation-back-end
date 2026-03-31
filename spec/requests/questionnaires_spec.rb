# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Questionnaires API', type: :request do
  include RolesHelper

  def auth_headers_for(user)
    token = JsonWebToken.encode(
      {
        id: user.id,
        name: user.name,
        full_name: user.full_name,
        role: user.role.name,
        institution_id: user.institution_id
      }
    )

    {
      'Authorization' => "Bearer #{token}",
      'Accept' => 'application/json'
    }
  end

  let!(:roles) { create_roles_hierarchy }
  let!(:institution) { create(:institution) }
  let!(:instructor) do
    User.create!(
      name: 'questspecuser',
      email: 'questspec@example.com',
      password: 'password',
      full_name: 'Questionnaire Spec User',
      institution: institution,
      role: roles[:instructor]
    )
  end
  let!(:other_instructor) do
    User.create!(
      name: 'otherquestspecuser',
      email: 'otherquestspec@example.com',
      password: 'password',
      full_name: 'Other Questionnaire Spec User',
      institution: institution,
      role: roles[:instructor]
    )
  end
  let!(:review_questionnaire) do
    Questionnaire.create!(
      name: 'Review Rubric',
      instructor: instructor,
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: 'ReviewQuestionnaire',
      display_type: 'Review'
    )
  end
  let!(:private_questionnaire) do
    Questionnaire.create!(
      name: 'Private Review Rubric',
      instructor: instructor,
      private: true,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: 'ReviewQuestionnaire',
      display_type: 'Review'
    )
  end
  let!(:public_quiz_questionnaire) do
    Questionnaire.create!(
      name: 'Quiz Rubric',
      instructor: other_instructor,
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: 'QuizQuestionnaire',
      display_type: 'Quiz'
    )
  end
  let!(:item_two) do
    Item.create!(
      questionnaire: review_questionnaire,
      txt: 'Second item',
      weight: 2,
      seq: 2,
      question_type: 'Scale',
      break_before: true
    )
  end
  let!(:item_one) do
    Item.create!(
      questionnaire: review_questionnaire,
      txt: 'First item',
      weight: 1,
      seq: 1,
      question_type: 'Criterion',
      break_before: true,
      size: '60,5'
    )
  end

  describe 'GET /questionnaires' do
    it 'returns questionnaires' do
      get '/questionnaires', headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.map { |record| record['id'] }).to include(review_questionnaire.id, private_questionnaire.id, public_quiz_questionnaire.id)
    end
  end

  describe 'GET /questionnaires/hierarchical' do
    it 'returns questionnaires grouped by display type for the current user' do
      get '/questionnaires/hierarchical', headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      review_group = json.find { |group| group['type'] == 'Review' }
      quiz_group = json.find { |group| group['type'] == 'Quiz' }

      expect(review_group).to be_present
      expect(review_group['questionnaires'].map { |record| record['id'] }).to include(review_questionnaire.id, private_questionnaire.id)
      expect(quiz_group['questionnaires'].map { |record| record['id'] }).to include(public_quiz_questionnaire.id)
    end
  end

  describe 'GET /questionnaires/:id/items' do
    it 'returns questionnaire items ordered by seq' do
      get "/questionnaires/#{review_questionnaire.id}/items", headers: auth_headers_for(instructor)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.map { |record| record['id'] }).to eq([item_one.id, item_two.id])
      expect(json.map { |record| record['txt'] }).to eq(['First item', 'Second item'])
    end
  end
end
