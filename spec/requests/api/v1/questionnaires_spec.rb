require 'swagger_helper'

RSpec.describe 'Questionnaire API', type: :request do

  path '/api/v1/questionnaire' do
    get('list questionnaires') do
      tags 'Questionnaires'
      produces 'application/json'

      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'invalid request') do
        let(:questionnaire) { { name: '', min_question_score: 1, max_question_score: 5,type: "" } }
        
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

   
    post('create questionnaire')do
      tags 'Questionnaires'
      consumes 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          type: { type: :string },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer }
        },
        required: [ 'name', 'type', 'min_question_score', 'max_question_score' ]
      }
  
      response(201, 'Created a questionnaire') do
        let(:questionnaire) { { name: 'Questionnaire 1', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
  
      response(422, 'invalid request') do
        let(:questionnaire) { { name: '', type: 'AuthorFeedbackQuestionnaire',min_question_score: 1, max_question_score: 5 } }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  
  path '/api/v1/questionnaires/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'ID of the questionnaire'
  
    get('show questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          private: { type: :boolean },
          instructor_id: { type: :integer },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          type: { type: :string },
          display_type: { type: :string },
          instruction_loc: { type: :string },
          created_at: { type: :string, format: :date_time },
          updated_at: { type: :string, format: :date_time }
        }
        required: [ 'name', 'type', 'min_question_score', 'max_question_score' ]
      }
  
      response(200, 'successful') do
        let(:id) { questionnaire.id }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
  
        run_test!
      end
  
      response(404, 'questionnaire not found') do
        let(:id) { -1 }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
  
        run_test!
      end
    end


   
    patch('update questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          private: { type: :boolean },
          instructor_id: { type: :integer },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          type: { type: :string },
          display_type: { type: :string },
          instruction_loc: { type: :string },
          created_at: { type: :string, format: :date_time },
          updated_at: { type: :string, format: :date_time }
        }
        required: [ 'name', 'type', 'min_question_score', 'max_question_score' ]
      }
  
      response(200, 'successful') do
        let(:id) { Questionnaire.create({ name: 'Questionnaire150', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } ).id }
        let(:questionnaire) { { name: 'Questionnaire100', type: 'AuthorFeedbackQuestionnaire',min_question_score: 1, max_question_score: 5 } }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
  
      response(422, 'invalid request') do
        let(:id) { Questionnaire.create({ name: 'Questionnaire150', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } ).id }
        let(:questionnaire) { { name: '', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
    
    put('update questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          private: { type: :boolean },
          instructor_id: { type: :integer },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          type: { type: :string },
          display_type: { type: :string },
          instruction_loc: { type: :string },
          created_at: { type: :string, format: :date_time },
          updated_at: { type: :string, format: :date_time }
        }
        required: [ 'name', 'type', 'min_question_score', 'max_question_score' ]
      }
    
      response(200, 'successful') do
        let(:id) { Questionnaire.create({ name: 'Questionnaire100', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } ).id }
        
        let(:questionnaire) { { name: 'Questionnaire101', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 }  }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    
      response(422, 'invalid request') do
        let(:id) { Questionnaire.create({ name: 'Questionnaire150', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } ).id }
        let(:questionnaire) { { name: '', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
    
   
    delete('delete Questionnaire') do
      tags 'Questionnaires'
      response(200, 'successful') do
        let(:id) { '123' }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    
      response(404, 'not found') do
        let(:id) { 'invalid_id' }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
    
  end

  path '/api/v1/questionnaires/copy/{id}' do
    post('copy questionnaire') do
      tags 'Questionnaires'
      consumes 'application/json'
      parameter name: :questionnaire, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          type: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer }
        },
        required: [ 'name', 'type', 'min_question_score', 'max_question_score' ]
      }
    
      response(200, 'successful') do
        let(:questionnaire) { { name: 'Questionnaire 1', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } }
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    
      response(500, 'server error') do
        let(:questionnaire) { { name: 'Questionnaire 1', type: 'AuthorFeedbackQuestionnaire', min_question_score: 1, max_question_score: 5 } }
  
        before do
          allow(Questionnaire).to receive(:copy_questionnaire_details).and_raise(StandardError)
        end
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
    



  end
end
