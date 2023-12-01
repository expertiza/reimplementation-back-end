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
    # Created by the group
    it 'returns a success response' do
      create_list(:questionnaire, 3, assignment: assignment)

      get :index
      expect(response).to be_successful
    end
    # Test scenario 1: When there are no questionnaires in the database
    # Expectation: The method should return an empty array
    # Method call: index
    # Expected output: []
    it 'returns all three quizzes' do
      create_list(:questionnaire, 0, assignment: assignment)

      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq(0)
    end

    # Test scenario 2: When there are multiple questionnaires in the database
    # Expectation: The method should return an array containing all the questionnaires
    # Method call: index
    # Expected output: [questionnaire1, questionnaire2, questionnaire3, ...]
    it 'returns all three quizzes' do
      create_list(:questionnaire, 3, assignment: assignment)

      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq(3)
    end

    # Test scenario 3: When there is only one questionnaire in the database
    # Expectation: The method should return an array containing the single questionnaire
    # Method call: index
    # Expected output: [questionnaire]
    it 'returns a total of one quiz' do
      create_list(:questionnaire, 1, assignment: assignment)

      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq(1)
    end

    # Test scenario 4: When the questionnaires have different attributes (e.g., title, description, created_at)
    # Expectation: The method should return an array containing all the questionnaires with their respective attributes
    # Method call: index
    # Expected output: [questionnaire1, questionnaire2, questionnaire3, ...]
    it 'returns correct quiz attributes' do
      pending 'unimplemented'
    end
  end
  
  describe 'GET #show' do
    let(:questionnaire) { create(:questionnaire, assignment: assignment, instructor: instructor) }

    before do
      get :show, params: { id: questionnaire.id }
    end
    context "when called" do
      it 'returns a success response' do
        expect(response).to be_successful
      end

      it "renders the student quiz as JSON" do
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(questionnaire.id)
      end
    end
  end

  describe 'POST #create_questionnaire' do
    context "when all parameters are valid" do
      before do
        post :create_questionnaire, params: questionnaire_params
      end
      it 'creates a new questionnaire' do
        unless response.status == 200
          puts response.body
        end
        expect(response).to have_http_status(:success)
      end
      it "creates a new questionnaire with questions and answers" do
        questionnaire = Questionnaire.last
        expect(questionnaire.questions.count).not_to be_zero
        expect(questionnaire.questions.first.answers.count).not_to be_zero
      end
    end

    context "when questionnaire parameters are missing" do
      it "returns an error message with status :unprocessable_entity" do
        # Test scenario 2
        pending 'unimplemented'
      end
    end

    context "when question parameters are missing" do
      it "returns an error message with status :unprocessable_entity" do
        # Test scenario 3
        pending 'unimplemented'
      end
    end

    context "when answer parameters are missing" do
      it "returns an error message with status :unprocessable_entity" do
        # Test scenario 4
        pending 'unimplemented'
      end
    end

    context "when an exception occurs during transaction" do
      it "returns an error message with status :unprocessable_entity" do
        # Test scenario 5
        pending 'unimplemented'
      end
    end
  end
  # describe "#update" do
  # end
  describe 'PATCH/PUT #update' do
    context "when the student quiz is successfully updated" do
      before do
        put :update, params: { id: questionnaire.id, questionnaire: updated_attributes }
      end
      it 'returns a success response' do
        expect(response).to have_http_status(:success)
      end
      it "returns the updated student quiz as JSON" do
        questionnaire.reload
        expect(questionnaire.name).to eq("Updated Quiz Name")
      end
    end

    context "when the student quiz fails to update" do
      it "returns the errors of the student quiz as JSON with status code 422" do
        # Test body
        pending 'unimplemented'
      end
    end
  end

  describe 'DELETE #destroy' do
    context "when a student quiz exists" do
      it "deletes the student quiz" do
        questionnaire_to_delete  # This line is to create the questionnaire before the test

        expect do
          delete :destroy, params: { id: questionnaire_to_delete.id }
        end.to change(Questionnaire, :count).by(-1)
      end

      it "returns a no_content status" do
        delete :destroy, params: { id: questionnaire_to_delete.id }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when a student quiz does not exist" do
      it "returns a no_content status" do
        pending 'unimplemented'
      end
    end
  end

  describe 'POST #assign_quiz_to_student' do
    context "when the quiz is not already assigned to the student" do
      before do
        post :assign_quiz_to_student, params: assign_quiz_params
      end
      it "assigns the quiz to the student" do
        expect(ResponseMap.where(reviewee_id: student.id, reviewed_object_id: questionnaire.id).exists?).to be true
      end

      it "returns a success response" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when the quiz is already assigned to the student" do
      before do
        create(:response_map, reviewee_id: student.id, reviewed_object_id: questionnaire.id)
        post :assign_quiz_to_student, params: assign_quiz_params
      end

      it 'does not create a new assignment' do
        expect(ResponseMap.where(reviewee_id: student.id, reviewed_object_id: questionnaire.id).count).to eq(1)
      end
      
      it "returns an error message" do
        pending 'unimplemented'
      end

      it "returns an unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when there is an error saving the response map" do
      it "returns an error message" do
        pending 'unimplemented'
      end

      it "returns an unprocessable entity status" do
        pending 'unimplemented'
      end
    end
  end

  describe 'POST #submit_answers' do
    context "when the user is not assigned to take the quiz" do
      it "returns a forbidden status and an error message" do
        # Test setup
        # ...

        # Test execution and assertion
        # ...
        pending 'unimplemented'
      end
    end

    context "when the user is assigned to take the quiz" do
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

      context "when all answers are correct" do
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

        it "saves the responses and updates the score of the ResponseMap" do
          # Test setup
          # ...

          # Test execution and assertion
          # ...
          pending 'unimplemented'
        end

        it "returns an OK status and the total score" do
          # Test setup
          # ...

          # Test execution and assertion
          # ...
          pending 'unimplemented'
        end
      end

      context "when some answers are incorrect" do
        it "saves the responses and updates the score of the ResponseMap" do
          # Test setup
          # ...

          # Test execution and assertion
          # ...
          pending 'unimplemented'
        end

        it "returns an OK status and the total score" do
          # Test setup
          # ...

          # Test execution and assertion
          # ...
          pending 'unimplemented'
        end
      end

      context "when there is an error saving the responses" do
        it "returns an unprocessable entity status and an error message" do
          # Test setup
          # ...

          # Test execution and assertion
          # ...
          pending 'unimplemented'
        end
      end
    end
  end

  # describe "calculate_score" do
  # end

  describe 'GET #calculate_score' do
    context "when the response map exists" do
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

      end
      it "returns the score of the response map" do
        # Test scenario 1
        # Given a valid response map ID
        # When the calculate_score method is called with the ID
        # Then it should return the score of the response map
        json_response = JSON.parse(response.body)
        expect(json_response['score']).to eq(2)

        # Test scenario 2
        # Given an invalid response map ID
        # When the calculate_score method is called with the ID
        # Then it should return an error message indicating that the attempt was not found or the user does not have permission to view the score
        #
        pending 'unimplemented'
      end
    end

    context "when the response map does not exist" do
      it "returns an error message" do
        # Test scenario 3
        # Given a non-existent response map ID
        # When the calculate_score method is called with the ID
        # Then it should return an error message indicating that the attempt was not found or the user does not have permission to view the score
        pending 'unimplemented'
      end
    end
  end

  describe "#set_student_quiz" do
    context "when given a valid questionnaire id" do
      it "sets @student_quiz to the questionnaire with the specified id" do
        # Test body
        pending 'unimplemented'
      end
    end

    context "when given an invalid questionnaire id" do
      it "does not set @student_quiz" do
        # Test body
        pending 'unimplemented'
      end
    end
  end


  describe "#questionnaire_params" do
    context "when valid parameters are provided" do
      it "returns the permitted parameters for a questionnaire" do
        # Test scenario 1
        # Description: All required parameters and nested attributes are provided
        # Method call: questionnaire_params
        # Input: {
        #   questionnaire: {
        #     name: "Sample Questionnaire",
        #     instructor_id: 1,
        #     min_question_score: 0,
        #     max_question_score: 10,
        #     assignment_id: 1,
        #     questions_attributes: [
        #       {
        #         id: 1,
        #         txt: "Question 1",
        #         question_type: "Multiple Choice",
        #         break_before: false,
        #         correct_answer: "Option A",
        #         score_value: 2,
        #         answers_attributes: [
        #           {
        #             id: 1,
        #             answer_text: "Option A",
        #             correct: true
        #           },
        #           {
        #             id: 2,
        #             answer_text: "Option B",
        #             correct: false
        #           }
        #         ]
        #       }
        #     ]
        #   }
        # }
        # Expected output: {
        #   name: "Sample Questionnaire",
        #   instructor_id: 1,
        #   min_question_score: 0,
        #   max_question_score: 10,
        #   assignment_id: 1,
        #   questions_attributes: [
        #     {
        #       id: 1,
        #       txt: "Question 1",
        #       question_type: "Multiple Choice",
        #       break_before: false,
        #       correct_answer: "Option A",
        #       score_value: 2,
        #       answers_attributes: [
        #         {
        #           id: 1,
        #           answer_text: "Option A",
        #           correct: true
        #         },
        #         {
        #           id: 2,
        #           answer_text: "Option B",
        #           correct: false
        #         }
        #       ]
        #     }
        #   ]
        # }

        # Test scenario 2
        # Description: Only required parameters are provided
        # Method call: questionnaire_params
        # Input: {
        #   questionnaire: {
        #     name: "Sample Questionnaire",
        #     instructor_id: 1,
        #     min_question_score: 0,
        #     max_question_score: 10,
        #     assignment_id: 1
        #   }
        # }
        # Expected output: {
        #   name: "Sample Questionnaire",
        #   instructor_id: 1,
        #   min_question_score: 0,
        #   max_question_score: 10,
        #   assignment_id: 1
        # }

        # Test scenario 3
        # Description: No parameters are provided
        # Method call: questionnaire_params
        # Input: {}
        # Expected output: {}
        pending 'unimplemented'
      end
    end
  end

  describe "#response_map_params" do
    context "when valid parameters are provided" do
      it "returns the permitted parameters for response_map" do
        # Test scenario 1: Valid student_id and questionnaire_id parameters are provided
        # Expected result: The method should return a hash with the permitted parameters
        pending 'unimplemented'

        # Test scenario 2: Only student_id parameter is provided
        # Expected result: The method should return a hash with the permitted student_id parameter
        pending 'unimplemented'

        # Test scenario 3: Only questionnaire_id parameter is provided
        # Expected result: The method should return a hash with the permitted questionnaire_id parameter
        pending 'unimplemented'
      end
    end

    context "when invalid parameters are provided" do
      it "raises an error" do
        # Test scenario 4: Invalid parameters are provided
        # Expected result: The method should raise an error indicating missing or invalid parameters
        pending 'unimplemented'
      end
    end
  end



  describe "#check_instructor_role" do
    context "when the current user is an instructor" do
      it "does not render an error message" do
        # Test body
        pending 'unimplemented'
      end
    end

    context "when the current user is not an instructor" do
      it "renders an error message with status :forbidden" do
        # Test body
        pending 'unimplemented'
      end
    end
  end
end
