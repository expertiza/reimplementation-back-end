require 'rails_helper'

RSpec.describe Api::V1::StudentQuizzesController, type: :controller do
  # Creates a student user
  let(:student) { create(:student) }
  # Creates an instructor user
  let(:instructor) { create(:instructor) }
  # Mock a token
  let(:auth_token) { 'mocked_auth_token' }
  # Creates a course for the tests
  let(:course) { create(:course, instructor: instructor) }
  # Creates an assignment
  let(:assignment) { create(:assignment, course: course) }
  # Creates the questionnaire json for testing the api
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
  # Creates a questionnaire
  let(:questionnaire) { create(:questionnaire, assignment: assignment, instructor: instructor) }
  # mock a questionnaire update
  let(:updated_attributes) do
    { name: "Updated Quiz Name" }
  end
  # Creates a questionnaire to delete to tests api endpoint
  let(:questionnaire_to_delete) { create(:questionnaire, assignment: assignment, instructor: instructor) }
  # Create the participant that links student to assignments
  let(:participant) { create(:participant, assignment: assignment, user: student) }
  # Creates the json for assigning a student to an assignment which is needed for the questionnaire
  let(:assign_quiz_params) do
    {
      participant_id: participant.id,
      questionnaire_id: questionnaire.id
    }
  end
  # Score to test the student quiz
  let(:known_score) { 2 }
  # create the response map needed for the student test and score api
  let(:response_map) { create(:response_map, reviewee_id: student.id, reviewed_object_id: questionnaire.id) }



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


  describe 'DELETE #destroy' do
    it 'destroys the requested questionnaire' do
      questionnaire_to_delete  # This line is to create the questionnaire before the test

      expect do
        delete :destroy, params: { id: questionnaire_to_delete.id }
      end.to change(Questionnaire, :count).by(-1)
    end

    it 'returns a no content response' do
      delete :destroy, params: { id: questionnaire_to_delete.id }
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST #assign_quiz_to_student' do
    context 'when the quiz is not already assigned' do
      before do
        post :assign_quiz_to_student, params: assign_quiz_params
      end

      it 'assigns the quiz to the student' do
        expect(ResponseMap.where(reviewee_id: student.id, reviewed_object_id: questionnaire.id).exists?).to be true
      end

      it 'returns a success response' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when the quiz is already assigned' do
      before do
        create(:response_map, reviewee_id: student.id, reviewed_object_id: questionnaire.id)
        post :assign_quiz_to_student, params: assign_quiz_params
      end

      it 'does not create a new assignment' do
        expect(ResponseMap.where(reviewee_id: student.id, reviewed_object_id: questionnaire.id).count).to eq(1)
      end

      it 'returns an unprocessable entity response' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST #submit_answers' do
    let!(:question1) do
      create(:question, questionnaire: questionnaire,
                              txt: "What is the capital of France?", correct_answer: "Paris")
    end
    let!(:question2) do
      create(:question, questionnaire: questionnaire,
                              txt: "What is the largest planet in our solar system?", correct_answer: "Jupiter")
    end

    let(:submit_answers_params) do
      {
        questionnaire_id: questionnaire.id,
        answers: [
          { question_id: question1.id, answer_value: "Paris" },
          { question_id: question2.id, answer_value: "Jupiter" }
        ]
      }
    end

    let!(:response_map) do
      create(:response_map, reviewee_id: student.id, reviewed_object_id: questionnaire.id)
    end

    before do
      allow_any_instance_of(Api::V1::StudentQuizzesController)
        .to receive(:current_user)
              .and_return(student)
      # Ensure questions are linked to answers correctly
      # Manually create answers for question1 and question2
      create(:answer, question: question1, answer_text: "Paris", correct: true)
      create(:answer, question: question1, answer_text: "Madrid", correct: false)
      create(:answer, question: question2, answer_text: "Jupiter", correct: true)
      create(:answer, question: question2, answer_text: "Mars", correct: false)

      post :submit_answers, params: submit_answers_params
    end

    it 'calculates the total score correctly' do
      json_response = JSON.parse(response.body)
      expect(json_response['total_score']).to eq(2)
    end

    it 'creates/updates response records' do
      expect(Response.where(response_map_id: response_map.id).count).to eq(submit_answers_params[:answers].length)
    end
  end



  describe 'GET #calculate_score' do
    # manually create the questionnaire questions and answers for the test
    let!(:question1) do
      create(:question, questionnaire: questionnaire,
             txt: "What is the capital of France?", correct_answer: "Paris")
    end
    let!(:question2) do
      create(:question, questionnaire: questionnaire,
             txt: "What is the largest planet in our solar system?", correct_answer: "Jupiter")
    end
    # Submit the answers in the json format for the test
    let(:submit_answers_params) do
      {
        questionnaire_id: questionnaire.id,
        answers: [
          { question_id: question1.id, answer_value: "Paris" },
          { question_id: question2.id, answer_value: "Jupiter" }
        ]
      }
    end
    # Create the response map that links the student to the assignment
    let!(:response_map) do
      create(:response_map, reviewee_id: student.id, reviewed_object_id: questionnaire.id, score: 2)
    end

    before do
      # take the quiz as the assigned student
      allow_any_instance_of(Api::V1::StudentQuizzesController)
        .to receive(:current_user)
              .and_return(student)

      # Manually create answers for question1 and question2
      create(:answer, question: question1, answer_text: "Paris", correct: true)
      create(:answer, question: question1, answer_text: "Madrid", correct: false)
      create(:answer, question: question2, answer_text: "Jupiter", correct: true)
      create(:answer, question: question2, answer_text: "Mars", correct: false)

      # Submit answers
      post :submit_answers, params: submit_answers_params

      # Switch to instructor for calculating score
      allow_any_instance_of(Api::V1::StudentQuizzesController)
        .to receive(:current_user)
              .and_return(instructor)

      # Retrieve score
      get :calculate_score, params: { id: response_map.id }

      # Debug the response
      puts "Response from calculate_score: #{response.body}"
    end

    it 'returns the score of the ResponseMap' do
      json_response = JSON.parse(response.body)
      expect(json_response['score']).to eq(2)
    end
  end

end
