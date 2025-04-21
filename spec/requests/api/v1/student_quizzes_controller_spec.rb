# spec/requests/api/v1/student_quizzes_spec.rb
require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentQuizzesController', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) {
    User.create!(
      name:                  "insta",
      password_digest:       "password",
      role_id:               @roles[:instructor].id,
      full_name:             "Instructor A",
      email:                 "instructor@example.com",
      mru_directory_path:    "/home/testuser"
    )
  }

  let(:student) {
    User.create!(
      name:                  "stud",
      password_digest:       "password",
      role_id:               @roles[:student].id,
      full_name:             "Student Student",
      email:                 "student@example.com",
      mru_directory_path:    "/home/testuser"
    )
  }

  # You referenced `assignment` in valid_attrs, so define it:
  let(:assignment) do
    Assignment.create!(
      instructor_id: instructor.id,
      name:          "Demo Assignment"
    )
  end

  let(:valid_attrs) do
    {
      questionnaire: { # Wrap attributes under `questionnaire`
        name: 'Questionnaire 1',
        questionnaire_type: 'Quiz',
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id,
        items_attributes: [
          {
            txt: 'What is 2+2?',
            question_type: 'short_answer',
            break_before: 1,
            weight: 1,
            skippable: false,
            seq: 1,
            quiz_question_choices_attributes: [
              { txt: '4', is_correct: true },
              { txt: '3', is_correct: false }
            ]
          }
        ]
      }
    }
  end

  # token‐based auth helpers
  let(:token)        { JsonWebToken.encode({ id: instructor.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  before do
    # stub out authentication & role check
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(instructor)
    allow_any_instance_of(Api::V1::StudentQuizzesController)
      .to receive(:check_instructor_role).and_return(true)
  end

  describe '#index' do
    it 'returns a list of quizzes' do
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'Quiz',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
      get '/api/v1/student_quizzes', headers: auth_headers

      expect(response).to have_http_status(:ok)
      quizzes = JSON.parse(response.body)
      expect(quizzes).to be_an(Array)
    end
  end

  describe '#create' do
    it 'creates a questionnaire with nested items and choices' do
      post api_v1_student_quizzes_path,
          params: valid_attrs.to_json,
          headers: auth_headers

      puts response.body
    
      # 👇 or pretty‑print the parsed JSON
      pp JSON.parse(response.body)
    
      expect(response).to have_http_status(:created)
    end
      
  end
end
