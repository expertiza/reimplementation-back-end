# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Nested Questionnaires API', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  let(:instructor) do
    User.create!(
      name: 'instructor_nested',
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor Nested',
      email: 'instructor_nested@example.com',
      institution: @institution
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' } }

  describe 'POST /questionnaires' do
    it 'creates a questionnaire with nested items even if seq is missing' do
      payload = {
        questionnaire: {
          name: 'Nested Questionnaire Test No Seq',
          questionnaire_type: 'Review rubric',
          private: false,
          min_question_score: 1,
          max_question_score: 10,
          instructor_id: instructor.id,
          items_attributes: [
            {
              txt: 'Question 1',
              question_type: 'Scale',
              weight: 5,
              break_before: true
              # seq is missing
            }
          ]
        }
      }

      post '/questionnaires', params: payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      
      questionnaire = Questionnaire.find(JSON.parse(response.body)['id'])
      expect(questionnaire.items.first.seq).to be_present
    end

    it 'allows break_before to be false' do
      payload = {
        questionnaire: {
          name: 'Nested Questionnaire Test False Break',
          questionnaire_type: 'Review rubric',
          private: false,
          min_question_score: 1,
          max_question_score: 10,
          instructor_id: instructor.id,
          items_attributes: [
            {
              txt: 'Question 1',
              question_type: 'Scale',
              weight: 5,
              break_before: false
            }
          ]
        }
      }

      post '/questionnaires', params: payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      
      questionnaire = Questionnaire.find(JSON.parse(response.body)['id'])
      expect(questionnaire.items.first.break_before).to be false
    end
  end
end
