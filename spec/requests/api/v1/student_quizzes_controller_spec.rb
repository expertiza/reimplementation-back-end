require 'swagger_helper'

RSpec.describe 'StudentQuizzes API', type: :request do
  let!(:role) { create(:role, name: "Instructor") } # Creating a role with the name "Instructor"
  let!(:instructor) { create(:user, role: role) } # Creating a user with the role created above
  let!(:student) { create(:user, role:'Student') }
  let!(:questionnaire) { create(:questionnaire, instructor_id: instructor.id) }
  let(:questionnaire_id) { questionnaire.id }
  let(:valid_attributes) do
    {
      questionnaire: {
        name: 'Quiz 1',
        instructor_id: instructor.id,
        min_question_score: 1,
        max_question_score: 5,
        assignment_id: create(:assignment).id,
        questions_attributes: [
          {
            txt: 'What is Ruby?',
            question_type: 'text',
            break_before: true,
            correct_answer: 'Programming Language',
            score_value: 1,
            answers_attributes: [
              { answer_text: 'Programming Language', correct: true },
              { answer_text: 'A Gem', correct: false }
            ]
          }
        ]
      }
    }
  end
  let(:invalid_attributes) do
    { questionnaire: { name: '' } }
  end

  describe 'POST /api/v1/student_quizzes' do
    context 'with valid parameters' do
      it 'creates a new Student Quiz' do
        expect {
          post '/api/v1/student_quizzes', params: valid_attributes
        }.to change(Questionnaire, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Student Quiz' do
        expect {
          post '/api/v1/student_quizzes', params: invalid_attributes
        }.to change(Questionnaire, :count).by(0)

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET /api/v1/student_quizzes/{quiz_id}/calculate_score' do
    it 'calculates score for a given quiz' do
      get "/api/v1/student_quizzes/#{questionnaire_id}/calculate_score"
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/v1/student_quizzes/assign' do
    let(:assign_attributes) do
      { participant_id: student.id, questionnaire_id: questionnaire_id }
    end

    it 'assigns a quiz to a student' do
      post '/api/v1/student_quizzes/assign', params: assign_attributes
      expect(response).to have_http_status(:created)
    end
  end

  describe 'POST /api/v1/student_quizzes/submit_answers' do
    let(:submit_attributes) do
      {
        questionnaire_id: questionnaire_id,
        answers: [
          { question_id: create(:question, questionnaire: questionnaire).id, answer_value: 'Programming Language' }
        ]
      }
    end

    it 'submits answers and calculates the total score' do
      post '/api/v1/student_quizzes/submit_answers', params: submit_attributes
      expect(response).to have_http_status(:ok)
    end
  end


  describe 'PUT /api/v1/student_quizzes/{id}' do
    let(:valid_attributes_update) do
      {
        questionnaire: {
          name: 'Updated Quiz Name',
        }
      }
    end

    context 'when the record exists' do
      before { put "/api/v1/student_quizzes/#{questionnaire_id}", params: valid_attributes_update }

      it 'updates the record' do
        expect(response).to have_http_status(:ok)
        updated_quiz = Questionnaire.find(questionnaire_id)
        expect(updated_quiz.name).to match(/Updated Quiz Name/)
      end
    end

    context 'when the record does not exist' do
      before { put "/api/v1/student_quizzes/#{questionnaire_id + 100}", params: valid_attributes_update } # Assuming an ID that does not exist

      it 'returns status code 404' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid parameters' do
      before { put "/api/v1/student_quizzes/#{questionnaire_id}", params: invalid_attributes }

      it 'returns status code 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/student_quizzes/{id}' do
    let!(:quiz_to_delete) { create(:questionnaire, instructor_id: instructor.id) }

    context 'when the record exists' do
      it 'deletes the record' do
        expect {
          delete "/api/v1/student_quizzes/#{quiz_to_delete.id}"
        }.to change(Questionnaire, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when the record does not exist' do
      before { delete "/api/v1/student_quizzes/#{quiz_to_delete.id + 100}" } # Assuming an ID that does not exist

      it 'returns status code 404' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
