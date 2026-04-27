# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'
# Rspec tests for questions controller
RSpec.describe 'questions', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) { User.create(
    name: "profa",
    password_digest: "password",
    role_id: @roles[:instructor].id,
    full_name: "Prof A",
    email: "testuser@example.com",
    mru_directory_path: "/home/testuser",
    ) }

  let!(:questionnaire) do
    instructor
    Questionnaire.create(
      name: 'Questionnaire 1',
      questionnaire_type: 'AuthorFeedbackReview',
      private: true,
      min_question_score: 0,
      max_question_score: 10,
      instructor_id: instructor.id
    )
  end

  let(:token) { JsonWebToken.encode({id: instructor.id}) }
  let(:Authorization) { "Bearer #{token}" }
  path '/questions' do
    let(:question1) do
      questionnaire
      Item.create(
        seq: 1, 
        txt: "test item 1",
        question_type: "multiple_choice", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:question2) do
      questionnaire
      Item.create(
        seq: 2, 
        txt: "test item 2",
        question_type: "multiple_choice", 
        break_before: false, 
        weight: 10,
        questionnaire: questionnaire
      )
    end

    # get request on /questions returns 200 successful response when it returns list of questions present in the database
    get('list questions') do
      tags 'Questions'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post('create item') do
      tags 'Questions'
      consumes 'application/json'
      produces 'application/json'
      
      let(:valid_question_params) do
        {
          questionnaire_id: questionnaire.id,
          txt: "test item",
          question_type: "multiple_choice", 
          break_before: false,
          seq: 1,
          weight: 10
        }
      end
      # Creation of dummy objects for the test with the help of let statements
      let(:invalid_question_params1) do
        {
          questionnaire_id: nil ,
          txt: "test item",
          question_type: "multiple_choice", 
          break_before: false,
          weight: 10
        }
      end

      let(:invalid_question_params2) do
        {
          questionnaire_id: questionnaire.id ,
          txt: "test item",
          question_type: nil, 
          break_before: false,
          weight: 10
        }
      end

      parameter name: :item, in: :body, schema: {
        type: :object,
        properties: {
          weight: { type: :integer },
          questionnaire_id: { type: :integer },
          break_before: { type: :boolean },
          txt: { type: :string },
          question_type: { type: :string },
        },
        required: %w[weight questionnaire_id break_before txt question_type]
      }

      # post request on /questions returns 201 created response and creates a item with given valid parameters
      response(201, 'created') do
        let(:item) { valid_question_params }
        run_test! do
          expect(response.body).to include('"seq":1')
        end
      end

      # post request on /questions returns 404 not found when questionnaire id for the given item is not present in the database
      response(404, 'questionnaire id not found') do
        let(:item) do
          instructor
          Item.create(invalid_question_params1)
        end
        run_test!
      end

      # post request on /questions returns 422 unprocessable entity when incorrect parameters are passed to create a item
      response(422, 'unprocessable entity') do
        let(:item) { invalid_question_params2 }   # <--- pass invalid params directly to the request
        run_test!
      end

    end

  end

  path '/questions/{id}' do

    parameter name: 'id', in: :path, type: :integer

    let(:question1) do
      questionnaire
      Item.create(
        seq: 1, 
        txt: "test item 1",
        question_type: "Scale", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:question2) do
      questionnaire
      Item.create(
        seq: 2, 
        txt: "test item 2",
        question_type: "Scale", 
        break_before: false, 
        weight: 10,
        questionnaire: questionnaire
      )
    end

    
    let(:id) do
      questionnaire
      question1
      question1.id 
    end



    get('show item') do
      tags 'Questions'
      produces 'application/json'

      # get request on /questions/{id} returns 200 successful response and returns item with given item id
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include('"txt":"test item 1"')
        end
      end

      # get request on /questions/{id} returns 404 not found response when item id is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
          run_test! do
            expect(response.body).to include("Couldn't find Item")
          end
      end
    end

    put('update item') do
      tags 'Questions'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          break_before: { type: :boolean },
          seq: { type: :integer }
        }
      }
      
      # put request on /questions/{id} returns 200 successful response and updates parameters of item with given item id
      response(200, 'successful') do
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include('"break_before":true')
        end
      end

      # put request on /questions/{id} returns 404 not found response when item with given id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include("Not Found")
        end
      end

      # put request on /questions/{id} returns 422 unprocessable entity when incorrect parameters are passed for item with given item id
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            seq: "Dfsd"
          }
        end
        schema type: :object
        run_test! do
          expect(response.body).to_not include('"seq":"Dfsd"')
        end
      end  


    end

    patch('update item') do
      tags 'Questions'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          break_before: { type: :boolean },
          seq: { type: :integer }
        }
      }
      
      # patch request on /questions/{id} returns 200 successful response and updates parameters of item with given item id
      response(200, 'successful') do
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include('"break_before":true')
        end
      end

      # patch request on /questions/{id} returns 404 not found response when item with given id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include("Couldn't find Item")
        end
      end

      # patch request on /questions/{id} returns 422 unprocessable entity when incorrect parameters are passed for item with given item id
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            seq: "Dfsd"
          }
        end
        schema type: :object
        run_test! do
          expect(response.body).to_not include('"seq":"Dfsd"')
        end
      end
    end


    delete('delete item') do

      tags 'Questions'
      produces 'application/json'

      # delete request on /questions/{id} returns 204 successful response when it deletes item with given item id present in the database
      response(204, 'successful') do
        run_test! do
          expect(Item.exists?(id)).to eq(false)
        end
      end

      # delete request on /questions/{id} returns 404 not found response when item with given item id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Item")
        end
      end
    end

  end

  path '/questions/delete_all/questionnaire/{id}' do
    parameter name: 'id', in: :path, type: :integer

    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:question1) do
      questionnaire
      Item.create(
        seq: 1, 
        txt: "test item 1",
        question_type: "multiple_choice", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:question2) do
      questionnaire
      Item.create(
        seq: 2, 
        txt: "test item 2",
        question_type: "multiple_choice", 
        break_before: false, 
        weight: 10,
        questionnaire: questionnaire
      )
    end

    
    let(:id) do
      questionnaire
      question1
      question2
      questionnaire.id 
    end

    delete('delete all questions') do
      tags 'Questions'
      produces 'application/json'

      # delete method on /questions/delete_all/questionnaire/{id} returns 200 successful response when all questions with given questionnaire id are deleted
      response(200, 'successful') do
        run_test! do
          expect(Item.where(questionnaire_id: id).count).to eq(0)
        end
      end

      # delete request on /questions/delete_all/questionnaire/{id} returns 404 not found response when questionnaire id is not found in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/questions/show_all/questionnaire/{id}' do
    parameter name: 'id', in: :path, type: :integer

    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:question1) do
      questionnaire
      Item.create(
        seq: 1, 
        txt: "test item 1",
        question_type: "multiple_choice", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:questionnaire2) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 2',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:question2) do
      questionnaire2
      Item.create(
        seq: 2, 
        txt: "test item 2",
        question_type: "multiple_choice", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire2
      )
    end

    let(:question3) do
      questionnaire2
      Item.create(
        seq: 3, 
        txt: "test item 3",
        question_type: "multiple_choice", 
        break_before: false, 
        weight: 10,
        questionnaire: questionnaire2
      )
    end

    
    let(:id) do
      questionnaire
      questionnaire2
      question1
      question2
      question3
      questionnaire.id 
    end

    get('show all questions') do
      tags 'Questions'
      produces 'application/json'

      # get method on /questions/show_all/questionnaire/{id} returns 200 successful response when all questions with given questionnaire id are shown
      response(200, 'successful') do
        run_test! do
          expect(Item.where(questionnaire_id: id).count).to eq(1)
          expect(response.body).to_not include('"questionnaire_id: "' + questionnaire2.id.to_s)
        end
      end

      # get request on /questions/delete_all/questionnaire/{id} returns 404 not found response when questionnaire id is not found in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/questions/types' do

    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:question1) do
      questionnaire
      Item.create(
        seq: 1, 
        txt: "test item 1",
        question_type: "multiple_choice", 
        break_before: true, 
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:question2) do
      questionnaire
      Item.create(
        seq: 2, 
        txt: "test item 2",
        question_type: "multiple_choice", 
        break_before: false, 
        weight: 10,
        questionnaire: questionnaire
      )
    end

    get('item types') do
      tags 'Questions'
      produces 'application/json'
      # get request on /questions/types returns types of questions present in the database
      response(200, 'successful') do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end
  
  end

  # -------------------------------------------------------------------------
  # E2619: GET /questions/quiz_types
  # Returns the list of item types allowed inside a Quiz questionnaire.
  # -------------------------------------------------------------------------
  path '/questions/quiz_types' do
    get('quiz item types') do
      tags 'Questions'
      produces 'application/json'

      # returns 200 with a JSON array of allowed quiz item type strings
      response(200, 'returns allowed quiz item types') do
        run_test! do
          types = JSON.parse(response.body)
          expect(types).to be_an(Array)
          expect(types).to include('TextField', 'MultipleChoiceRadio', 'MultipleChoiceCheckbox',
                                   'Scale', 'Checkbox')
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # E2619: POST /questions for quiz questionnaires
  # Validates that only allowed quiz item types are accepted and that
  # correct_answer is stored.
  # -------------------------------------------------------------------------
  path '/questions' do
    let(:quiz_questionnaire) do
      instructor
      Questionnaire.create!(
        name: 'My Quiz',
        questionnaire_type: 'Quiz',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor_id: instructor.id
      )
    end

    post('create quiz item') do
      tags 'Questions'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :item, in: :body, schema: {
        type: :object,
        properties: {
          questionnaire_id: { type: :integer },
          txt:              { type: :string },
          question_type:    { type: :string },
          weight:           { type: :integer },
          correct_answer:   { type: :string }
        },
        required: %w[questionnaire_id txt question_type]
      }

      # creates a quiz item with a correct_answer when type is valid
      response(201, 'creates quiz item and stores correct_answer') do
        let(:item) do
          {
            questionnaire_id: quiz_questionnaire.id,
            txt:              'What is the capital of France?',
            question_type:    'TextField',
            seq:              1,
            weight:           2,
            correct_answer:   'Paris'
          }
        end
        run_test! do
          data = JSON.parse(response.body)
          expect(data['correct_answer']).to eq('Paris')
        end
      end

      # rejects an invalid quiz item type with 422
      response(422, 'rejects invalid quiz item type') do
        let(:item) do
          {
            questionnaire_id: quiz_questionnaire.id,
            txt:              'What is your name?',
            question_type:    'TextArea',   # not allowed in a quiz
            seq:              1,
            weight:           1
          }
        end
        run_test! do
          data = JSON.parse(response.body)
          expect(data['error']).to include('Invalid quiz item type')
        end
      end
    end
  end

end