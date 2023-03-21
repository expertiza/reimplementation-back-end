require 'swagger_helper'

RSpec.describe 'SignUpTopicController API', type: :request do
  #creat
  path '/api/v1/sign_up_topics' do
    post('create a new topic in the sheet') do
     tags 'SignUpTopic'
     consumes 'application/json'
     parameter name: :sign_up_topic, in: :body, schema: {
       type: :object,
       properties: {
         'sign_up_topic': {
           type: :object,
           properties: {
               topic_identifier: { type: :integer },
               topic_name: { type: :string },
               max_choosers: { type: :integer },
               category: {type: :string},
               assignment_id: {type: :integer},
               micropayment: {type: :integer}
           }
         }
       },
       required: [ 'topic_identifier', 'topic_name', 'max_choosers', 'category', 'assignment_id','micropayment' ]
     }
      response(200, 'successful') do
        let(:topic) { { topic_identifier: 1 } }
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

  path '/api/v1/sign_up_topics/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'

    put('update a new topic in the sheet') do
      tags 'SignUpTopic'
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          sign_up_topic: {
            type: :object,
            properties: {
              topic_identifier: { type: :integer },
              topic_name: { type: :string },
              max_choosers: { type: :integer },
              category: {type: :string},
              assignment_id: {type: :integer},
              micropayment: {type: :integer}
            }
          }
        },
        required: [ 'topic_identifier', 'topic_name', 'category', 'assignment_id']
      }

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
    end
  end

  path '/api/v1/sign_up_topics/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'

    put('update a new topic in the sheet') do
      tags 'SignUpTopic'
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          sign_up_topic: {
            type: :object,
            properties: {
              topic_identifier: { type: :integer },
              topic_name: { type: :string },
              max_choosers: { type: :integer },
              category: {type: :string},
              assignment_id: {type: :integer},
              micropayment: {type: :integer}
            }
          }
        },
        required: [ 'topic_identifier', 'topic_name', 'category', 'assignment_id']
      }

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
    end

    delete('delete sign up topic') do
      tags 'SignUpTopic'
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
    end
  end

  path '/api/v1/sign_up_topics/load_all_selected_topics' do
    get('list the topics') do
      tags 'SignUpTopic'
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
    end
  end

  path '/api/v1/sign_up_topics/delete_all_selected_topics' do
    post('test for all selected topics') do
      tags 'SignUpTopic'
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
    end
  end

  path '/api/v1/sign_up_topics/delete_all_topics_for_assignment' do
    post('test to delete topics') do
      tags 'SignUpTopic'
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
    end
  end


end

