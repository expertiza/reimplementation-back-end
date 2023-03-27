require 'swagger_helper'

RSpec.describe 'Question API', type: :request do

  path '/api/v1/question' do
    get('list questions') do
      tags 'Questions'
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
        #need to check and update this
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }
    
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
  
    post('create question') do
      tags 'Questions'
      consumes 'application/json'
      parameter name: :question, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          question: {
            type: :object,
            properties: {
              txt: { type: :string },
              weight: { type: :integer },
              questionnaire_id: { type: :integer },
              seq: { type: :string },
              size: { type: :string },
              alternatives: { type: :string },
              break_before: { type: :boolean },
              max_label: { type: :string },
              min_label: { type: :string },
              type: { type: :string },
            },
            required: ['type' ]
          }
        },
        required: [ 'question' ]
      }
    
      response(201, 'Created a question') do
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    
      response(422, 'Invalid request') do
        let(:question) { { question: { txt: '', questionnaire_id: 692, seq: '9.0', type: 'Dropdown' } } }
    
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
  
  path '/api/v1/questions/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'ID of the question'

    get('show question') do
      tags 'Questions'
      consumes 'application/json'
      parameter name: :question, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          question: {
            type: :object,
            properties: {
              txt: { type: :string },
              weight: { type: :integer },
              questionnaire_id: { type: :integer },
              seq: { type: :string },
              size: { type: :string },
              alternatives: { type: :string },
              break_before: { type: :boolean },
              max_label: { type: :string },
              min_label: { type: :string },
              type: { type: :string },
            },
            required: ['type' ]
          }
        },
        required: [ 'question' ]
      }
    
      response(200, 'successful') do
        let(:id) { question.id }
    
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
    
        run_test!
      end
    
      response(404, 'question not found') do
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
    

    patch('update question') do
      tags 'Questions'
      consumes 'application/json'
      parameter name: :question, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          question: {
            type: :object,
            properties: {
              txt: { type: :string },
              weight: { type: :integer },
              questionnaire_id: { type: :integer },
              seq: { type: :string },
              size: { type: :string },
              alternatives: { type: :string },
              break_before: { type: :boolean },
              max_label: { type: :string },
              min_label: { type: :string },
              type: { type: :string },
            },
            required: ['type' ]
          }
        },
        required: [ 'question' ]
      }
  
      response(200, 'successful') do
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }

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
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: nil } } }
    
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
  
      response(404, 'question not found') do
        let(:question) { { id: -1, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }
    
  
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
 
    put('update question') do
      tags 'Questions'
      consumes 'application/json'
      parameter name: :question, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          question: {
            type: :object,
            properties: {
              txt: { type: :string },
              weight: { type: :integer },
              questionnaire_id: { type: :integer },
              seq: { type: :string },
              size: { type: :string },
              alternatives: { type: :string },
              break_before: { type: :boolean },
              max_label: { type: :string },
              min_label: { type: :string },
              type: { type: :string },
            },
            required: ['type' ]
          }
        },
        required: [ 'question' ]
      }
  
      response(200, 'successful') do
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }

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
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: nil } } }
    
  
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
  
      response(404, 'question not found') do
        let(:question) { { id: -1, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }
    
  
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
    
    delete('delete Question') do
      tags 'Questions'
      response(200, 'successful') do
        let(:question) { { id: 6, question: { txt: 'This is a test', weight: 1, questionnaire_id: 692, seq: '9.0', size: nil, alternatives: nil, break_before: true, max_label: nil, min_label: nil, type: 'Dropdown' } } }
        let(:id) { question.id }
    
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

end
