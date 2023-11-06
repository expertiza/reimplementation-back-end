
require 'swagger_helper'

RSpec.describe 'Api::V1::QuizQuestionnaires', type: :request do
  path '/api/v1/quiz_questionnaires' do
    post 'Create a quiz questionnaire' do
      tags 'Quiz Questionnaires'
      consumes 'application/json'
      parameter name: :quiz_questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          questionnaire_type: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          instructor_id: { type: :integer },
          assignment_id: { type: :integer }
        },
        required: ['name', 'questionnaire_type', 'private', 'min_question_score', 'max_question_score', 'instructor_id', 'assignment_id']
      }

      response '201', 'Quiz questionnaire created' do
        run_test! do
          # Provide valid data for a successful creation
          let(:quiz_questionnaire) do
            {
              name: 'Sample Quiz',
              questionnaire_type: 'Quiz Questionnaire',
              private: false,
              min_question_score: 0,
              max_question_score: 100,
              instructor_id: 1,
              assignment_id: 1
            }
          end
        end
      end

      response '422', 'Unprocessable Entity' do
        run_test! do
          # Provide incomplete or invalid data to trigger a 422 response
          let(:quiz_questionnaire) do
            {
              name: '', # Invalid: Name is required
              questionnaire_type: '', # Invalid: Type is required
              private: nil, # Invalid: Private should be a boolean
              min_question_score: -1, # Invalid: Min score should be non-negative
              max_question_score: 50, # Invalid: Max score should be greater than min score
              instructor_id: 'invalid_id', # Invalid: Instructor ID should be an integer
              assignment_id: nil # Invalid: Assignment ID is required
            }
          end
        end
      end
    end

    get 'List quiz questionnaires' do
      tags 'Quiz Questionnaires'
      produces 'application/json'

      response '200', 'List of quiz questionnaires' do
        run_test! do
          # Test response data or expectations
        end
      end
    end
  end

  path '/api/v1/quiz_questionnaires/{id}' do
    parameter name: :id, in: :path, type: :string

    get 'Retrieve a quiz questionnaire' do
      tags 'Quiz Questionnaires'
      produces 'application/json'

      response '200', 'Quiz questionnaire details' do
        run_test! do
          # Provide the test scenario to retrieve a quiz questionnaire by ID
          # Example data:
          let(:id) { '1' }
        end
      end

      response '404', 'Not Found' do
        run_test! do
          # Provide a scenario that triggers a 404 response
          # Example data:
          let(:id) { '999' } # An ID that does not exist
        end
      end
    end

    put 'Update a quiz questionnaire' do
      tags 'Quiz Questionnaires'
      consumes 'application/json'
      parameter name: :quiz_questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          # Define the properties for updating a quiz questionnaire
          name: { type: :string },
          questionnaire_type: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          instructor_id: { type: :integer },
          assignment_id: { type: :integer }
        },
        required: ['name', 'questionnaire_type', 'private', 'min_question_score', 'max_question_score', 'instructor_id', 'assignment_id']
      }

      response '200', 'Quiz questionnaire updated' do
        run_test! do
          # Provide the request body data to update a quiz questionnaire
          # Example data:
          let(:quiz_questionnaire) do
            {
              name: 'Updated Quiz',
              questionnaire_type: 'Quiz Questionnaire',
              private: true,
              min_question_score: 5,
              max_question_score: 50,
              instructor_id: 1,
              assignment_id: 1
            }
          end
        end
      end

      response '422', 'Unprocessable Entity' do
        run_test! do
          # Provide invalid or incomplete data to trigger a 422 response
          let(:quiz_questionnaire) do
            {
              name: '', # Invalid: Name is required
              questionnaire_type: '', # Invalid: Type is required
              private: nil, # Invalid: Private should be a boolean
              min_question_score: -1, # Invalid: Min score should be non-negative
              max_question_score: 10, # Invalid: Max score should be less than min score
              instructor_id: 'invalid_id', # Invalid: Instructor ID should be an integer
              assignment_id: nil # Invalid: Assignment ID is required
            }
          end
        end
      end
    end

    delete 'Delete a quiz questionnaire' do
      tags 'Quiz Questionnaires'

      response '200', 'Quiz questionnaire deleted' do
        run_test! do
          # Provide the scenario to delete a quiz questionnaire
          # Example data:
          let(:id) { '1' } # ID of the quiz questionnaire to be deleted
        end
      end

      response '404', 'Not Found' do
        run_test! do
          # Provide a scenario that triggers a 404 response
          # Example data:
          let(:id) { '999' } # An ID that does not exist
        end
      end
    end
  end
end

