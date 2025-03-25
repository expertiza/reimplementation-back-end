require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentQuizzesController', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end
  
  let(:instructor) {
    User.create(
      name: "insta",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor A",
      email: "instructor@example.com",
      mru_directory_path: "/home/testuser"
    )
  }

  let(:student) {
    User.create(
      name: "stud",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Student",
      email: "student@example.com",
      mru_directory_path: "/home/testuser"
    )
  }

  # Embed token based authentication for tests
  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(instructor)
    allow_any_instance_of(Api::V1::StudentQuizzesController).to receive(:check_instructor_role).and_return(true)
  end

  describe '#index' do
    it "returns a list of quizzes" do
      # Create a sample quiz first.
      Questionnaire.create!(name: "Quiz One", instructor_id: instructor.id,
                              min_question_score: 0, max_question_score: 10)
      get '/api/v1/student_quizzes', headers: auth_headers
      expect(response).to have_http_status(:ok)
      quizzes = JSON.parse(response.body)
      expect(quizzes).to be_an(Array)
    end
  end

  describe '#create' do
    let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: instructor.id) }
    let(:quiz_params) do
      {
        questionnaire: {
          name: 'New Quiz',
          instructor_id: instructor.id,
          min_question_score: 1,
          max_question_score: 5,
          assignment_id: assignment.id,
          questionnaire_type: "Quiz",   # added required field
          private: false,               # added required field
          questions_attributes: [
            {
              seq: 1,
              txt: 'What is Ruby?',
              question_type: 'MultipleChoiceCheckbox',
              break_before: false,
              score_value: 1,
              correct_answer: nil,
              answers_attributes: [
                {
                  answer_text: 'A gemstone',
                  correct: false
                },
                {
                  answer_text: 'A programming language',
                  correct: true
                }
              ]
            }
          ]
        }
      }
    end

    it "creates a new quiz with questions and answers" do
      post '/api/v1/student_quizzes', params: quiz_params.to_json, headers: auth_headers
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["name"]).to eq("New Quiz")
      expect(data).to have_key("questions")
    end
  end

  describe '#destroy' do
    it "destroys an existing quiz" do
      quiz = Questionnaire.create!(name: "Quiz To Delete", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      delete "/api/v1/student_quizzes/#{quiz.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)
      expect { Questionnaire.find(quiz.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#show' do
    it "shows an existing quiz" do
      quiz = Questionnaire.create!(name: "Quiz Show", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      get "/api/v1/student_quizzes/#{quiz.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["id"]).to eq(quiz.id)
      expect(data["name"]).to eq("Quiz Show")
    end
  end

  let(:dummy_assignment) { Assignment.create!(name: "Dummy Assignment") }

  describe '#assign_quiz' do
    let(:dummy_assignment) { Assignment.create!(name: "Dummy Assignment", instructor_id: instructor.id) }
    it "assigns a quiz to a participant" do
      participant = Participant.create!(user_id: student.id, assignment_id: dummy_assignment.id)
      quiz = Questionnaire.create!(name: "Quiz To Assign", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      params = { participant_id: participant.id, questionnaire_id: quiz.id }
      post "/api/v1/student_quizzes/assign", params: params.to_json, headers: auth_headers
      expect(response).to have_http_status(:created)
    end
  end

  describe '#submit_quiz' do
    it "submits quiz answers and returns total score" do
      # Create a quiz and a response map for the current student.
      quiz = Questionnaire.create!(name: "Quiz Submit", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      response_map = ResponseMap.create!(reviewee_id: student.id,
                                         reviewer_id: quiz.instructor_id,
                                         reviewed_object_id: quiz.id, score: 0)
      submission_params = {
        questionnaire_id: quiz.id,
        answers: [ { question_id: 1, answer: 1 } ]
      }
      post "/api/v1/student_quizzes/submit_answers", params: submission_params.to_json, headers: auth_headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data).to have_key("total_score")
    end
  end

  describe '#update' do
    it "updates the quiz successfully" do
      quiz = Questionnaire.create!(name: "Old Quiz Name", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      update_params = { questionnaire: { name: "Updated Quiz Name" } }
      put "/api/v1/student_quizzes/#{quiz.id}", params: update_params.to_json, headers: auth_headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["name"]).to eq("Updated Quiz Name")
    end
  end

  describe '#fetch_quiz' do
    it "retrieves a quiz using the fetch_quiz logic" do
      quiz = Questionnaire.create!(name: "Fetch Quiz", instructor_id: instructor.id,
                                     min_question_score: 0, max_question_score: 10)
      get "/api/v1/student_quizzes/#{quiz.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["name"]).to eq("Fetch Quiz")
    end
  end

  describe '#render_success' do
    it "renders a success response when invoked via an action" do
      # Using the index action, which calls render_success.
      get "/api/v1/student_quizzes", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end
end