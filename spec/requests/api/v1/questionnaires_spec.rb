require 'swagger_helper'
require 'json_web_token'

# Rspec test for Questionnaires Controller
RSpec.describe 'api/v1/questionnaires', type: :request do

  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:prof) {
    User.create(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: prof.id}) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/questionnaires' do
    let(:questionnaire1) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: prof.id
      )
    end

    let(:questionnaire2) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 2',
        questionnaire_type: 'AuthorFeedbackReview',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor_id: prof.id
      )
    end

    # get request on /api/v1/questionnaires return list of questionnaires with response 200
    get('list questionnaires') do
      tags 'Questionnaires'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post('create questionnaire') do
      let(:valid_questionnaire_params) do
        {
          name: 'Test Questionnaire',
          questionnaire_type: 'AuthorFeedbackReview',
          private: false,
          min_question_score: 0,
          max_question_score: 5,
          instructor_id: prof.id
        }
      end

      let(:invalid_questionnaire_params) do
        {
          name: nil, # invalid name
          questionnaire_type: 'AuthorFeedbackReview',
          private: false,
          min_question_score: 0,
          max_question_score: 5,
          instructor_id: prof.id
        }
      end

      consumes 'application/json'
      produces 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          questionnaire_type: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          instructor_id: { type: :integer}
        },
        required: %w[id name questionnaire_type private min_question_score max_question_score instructor_id]
      }

      # post request on /api/v1/questionnaires creates questionnaire with response 201 when correct params are passed
      response(201, 'created') do
        let(:questionnaire) do
          prof
          Questionnaire.create(valid_questionnaire_params)
        end
        run_test! do
          expect(response.body).to include('"name":"Test Questionnaire"')
        end
      end

      # post request on /api/v1/questionnaires returns 422 response - unprocessable entity when wrong params is passed to create questionnaire
      response(422, 'unprocessable entity') do
        let(:questionnaire) do
          prof
          Questionnaire.create(invalid_questionnaire_params)
        end
        run_test!
      end
    end

  end

  path '/api/v1/questionnaires/{id}' do
    parameter name: 'id', in: :path, type: :integer
    let(:valid_questionnaire_params) do
      {
        name: 'Test Questionnaire',
        questionnaire_type: 'AuthorFeedbackReview',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor_id: prof.id
      }
    end

    let(:questionnaire) do
      prof
      Questionnaire.create(valid_questionnaire_params)
    end

    let(:id) do
      questionnaire
      questionnaire.id
    end

    # Get request on /api/v1/questionnaires/{id} returns the response 200 successful - questionnaire with id = {id} when correct id is passed which is in the database
    get('show questionnaire') do
      tags 'Questionnaires'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include('"name":"Test Questionnaire"')
        end
      end

      # Get request on /api/v1/questionnaires/{id} returns the response 404 not found - questionnaire with id = {id} when correct id is passed which is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end

    put('update questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          min_question_score: { type: :integer }
        }
      }

      # put request on /api/v1/questionnaires/{id} returns 200 response successful when questionnaire id is present in the database and correct valid params are passed
      response(200, 'successful') do
        let(:body_params) do
          {
            min_question_score: 1
          }
        end
        run_test! do
          expect(response.body).to include('"min_question_score":1')
        end
      end

      # put request on /api/v1/questionnaires/{id} returns 404 not found when id is not present in the database which questionnaire needs to be updated
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            min_question_score: 0
          }
        end
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end

      # put request on /api/v1/questionnaires/{id} returns 422 response unprocessable entity when correct parameters for the questionnaire to be updated are not passed
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            min_question_score: -1
          }
        end
        schema type: :array, items: { type: :string }
        run_test! do
          expect(response.body).to_not include('"min_question_score":-1')
        end
      end
    end

    patch('update questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          min_question_score: { type: :integer }
        }
      }

      # patch request on /api/v1/questionnaires/{id} returns 200 response successful when questionnaire id is present in the database and correct valid params are passed
      response(200, 'successful') do
        let(:body_params) do
          {
            min_question_score: 1
          }
        end
        run_test! do
          expect(response.body).to include('"min_question_score":1')
        end
      end

      # patch request on /api/v1/questionnaires/{id} returns 404 not found when id is not present in the database which questionnaire needs to be updated
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            min_question_score: 0
          }
        end
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end

      # patch request on /api/v1/questionnaires/{id} returns 422 response unprocessable entity when correct parameters for the questionnaire to be updated are not passed
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            min_question_score: -1
          }
        end
        schema type: :array, items: { type: :string }
        run_test! do
          expect(response.body).to_not include('"min_question_score":-1')
        end
      end
    end

    delete('delete questionnaire') do
      tags 'Questionnaires'
      produces 'application/json'
      # delete request on /api/v1/questionnaires/{id} returns 204 successful response when questionnaire with id present in the database is successfully deleted
      response(204, 'successful') do
        run_test! do
          expect(Questionnaire.exists?(id)).to eq(false)
        end
      end

      # delete request on /api/v1/questionnaires/{id} returns 404 not found response when questionnaire id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/api/v1/questionnaires/toggle_access/{id}' do
    parameter name: 'id', in: :path, type: :integer
    let(:valid_questionnaire_params) do
      {
        name: 'Test Questionnaire',
        questionnaire_type: 'AuthorFeedbackReview',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor_id: prof.id
      }
    end

    let(:questionnaire) do
      prof
      Questionnaire.create(valid_questionnaire_params)
    end

    let(:id) do
      questionnaire
      questionnaire.id
    end


    get('toggle access') do
      tags 'Questionnaires'
      produces 'application/json'

      # get request on /api/v1/questionnaires/toggle_access/{id} returns 200 successful response when correct id is passed and toggles the private variable
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include(" has been successfully made private. ")
        end
      end

      # get request on /api/v1/questionnaires/toggle_access/{id} returns 404 not found response when questionnaire id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/api/v1/questionnaires/copy/{id}' do
    parameter name: 'id', in: :path, type: :integer
    let(:valid_questionnaire_params) do
      {
        name: 'Test Questionnaire',
        questionnaire_type: 'AuthorFeedbackReview',
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        instructor_id: prof.id
      }
    end

    let(:questionnaire) do
      prof
      Questionnaire.create(valid_questionnaire_params)
    end

    let(:id) do
      questionnaire
      questionnaire.id
    end

    post('copy questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      produces 'application/json'

      # post request on /api/v1/questionnaires/copy/{id} returns 200 successful response when request returns copied questionnaire with questionnaire id is present in the database
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include('"name":"Copy of Test Questionnaire"')
        end
      end

      # post request on /api/v1/questionnaires/copy/{id} returns 404 not found response when questionnaire id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end
end
