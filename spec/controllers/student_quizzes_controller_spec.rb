require 'rails_helper'

RSpec.describe Api::V1::StudentQuizzesController, type: :controller do
  let(:student) { create(:student) }       # Creates a student user
  let(:instructor) { create(:instructor) } # Creates an instructor user
  let(:auth_token) { 'mocked_auth_token' } # Mock a token

  let(:course) { create(:course, instructor: instructor) }
  let(:assignment) { create(:assignment, course: course) }

  let(:questionnaire_params) do
    {
      "questionnaire": {
        "name": "General Knowledge Quiz",
        "instructor_id": instructor.id,
        "assignment_id": assignment.id,
        "min_question_score": 0,
        "max_question_score": 5,
        "questions_attributes": [
          {
            "txt": "What is the capital of France?",
            "question_type": "multiple_choice",
            "break_before": true,
            "correct_answer": "Paris",
            "score_value": 1,
            "answers_attributes": [
              { "answer_text": "Paris", "correct": true },
              { "answer_text": "Madrid", "correct": false },
              { "answer_text": "Berlin", "correct": false },
              { "answer_text": "Rome", "correct": false }
            ]
          },
          {
            "txt": "What is the largest planet in our solar system?",
            "question_type": "multiple_choice",
            "break_before": true,
            "correct_answer": "Jupiter",
            "score_value": 1,
            "answers_attributes": [
              { "answer_text": "Earth", "correct": false },
              { "answer_text": "Jupiter", "correct": true },
              { "answer_text": "Mars", "correct": false },
              { "answer_text": "Saturn", "correct": false }
            ]
          }
        ]
      }
    }
  end
  # mock a questionnaire
  let(:questionnaire) { create(:questionnaire, assignment: assignment, instructor: instructor) }

  # mock a questionnaire update
  let(:updated_attributes) do
    { name: "Updated Quiz Name" }
  end


  before do
    allow_any_instance_of(Api::V1::StudentQuizzesController)
      .to receive(:authenticate_request!)
            .and_return(true)

    allow_any_instance_of(Api::V1::StudentQuizzesController)
      .to receive(:current_user)
            .and_return(instructor)

    request.headers['Authorization'] = "Bearer #{auth_token}"
  end

  describe 'GET #index' do
    before do
      create_list(:questionnaire, 3, assignment: assignment)

      get :index
    end

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'returns all quizzes' do
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq(3)
    end
  end

  describe 'GET #show' do
    let(:questionnaire) { create(:questionnaire, assignment: assignment, instructor: instructor) }

    before do
      get :show, params: { id: questionnaire.id }
    end

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'returns the requested questionnaire data' do
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(questionnaire.id)
    end
  end

  describe 'POST #create_questionnaire' do
    before do
      post :create_questionnaire, params: questionnaire_params
    end

    it 'creates a new questionnaire' do
      unless response.status == 200
        puts response.body
      end
      expect(response).to have_http_status(:success)
    end

    it 'creates questions and answers for the questionnaire' do
      questionnaire = Questionnaire.last
      expect(questionnaire.questions.count).not_to be_zero
      expect(questionnaire.questions.first.answers.count).not_to be_zero
    end
  end

  describe 'PATCH/PUT #update' do
    before do
      put :update, params: { id: questionnaire.id, questionnaire: updated_attributes }
    end

    it 'updates the requested questionnaire' do
      questionnaire.reload
      expect(questionnaire.name).to eq("Updated Quiz Name")
    end

    it 'returns a success response' do
      expect(response).to have_http_status(:success)
    end
  end

end
