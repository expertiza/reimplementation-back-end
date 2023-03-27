require 'swagger_helper'
#all tests follow a similar json header
#test 1 to check if a topic can be created sucessfully.
RSpec.describe 'SignUpTopicController API', type: :request do
  #test 1 to check if a topic can be created sucessfully.
  path '/api/v1/sign_up_topics' do
    post('create a new topic in the sheet') do
     tags 'SignUpTopic'
     consumes 'application/json'
     #inputs are from the sign up topic table with properties as ID, name, choosers
     # assignment ID and micropayment
     parameter name: :sign_up_topic, in: :body, schema: {
       type: :object,
       properties: {
         topic_identifier: { type: :integer },
         topic_name: { type: :string },
         max_choosers: { type: :integer },
         category: {type: :string},
         assignment_id: {type: :integer},
         micropayment: {type: :integer}
       },
       #the test will require these inputs to pass
       required: [ 'topic_identifier', 'topic_name', 'max_choosers', 'category', 'assignment_id','micropayment' ]
     }
      response(201, 'Success') do
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
     response(404, 'Not Found') do
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
     response(422, 'Invalid Request') do
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
  # TEST 2 to update a new topic in the sheet
  path '/api/v1/sign_up_topics/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'
    #To update the topic a ID is inputted as a parameter, the topic for this ID must exist
    # in the database.
    put('update a new topic in the sheet') do
      tags 'SignUpTopic'
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
          properties: {
            topic_identifier: { type: :integer },
            topic_name: { type: :string },
            max_choosers: { type: :integer },
            category: {type: :string},
            assignment_id: {type: :integer},
            micropayment: {type: :integer}
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
      response(404, 'Not Found') do
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
      response(422, 'Invalid Request') do
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
  #test 3 to delete and update a topic
  path '/api/v1/sign_up_topics/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'

    put('update a new topic in the sheet') do
      tags 'SignUpTopic'
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          topic_identifier: { type: :integer },
          topic_name: { type: :string },
          max_choosers: { type: :integer },
          category: {type: :string},
          assignment_id: {type: :integer},
          micropayment: {type: :integer}
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
      response(404, 'Not Found') do
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
  #test 4 - to load topics based on assignment and topic ID.
  path '/api/v1/sign_up_topics/filter' do
    get('Get topics based on Assignment ID and Topic Identifiers filter') do
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
      parameter name: 'topic_ids[]', in: :query, type: :array, description: 'Topic Identifiers', collectionFormat: :multi

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
    #test 5 - to load topics based on assignment and topic ID.
    delete('Delete based on Assignment ID and Topic identifier filter') do
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: {type: :integer},
          topic_ids: {
            type: :array,
            items: {
              type: :string
            }
          }
        },
        required: ['assignment_id']
      }
      tags 'SignUpTopic'
      produces 'application/json'
      response(200, 'Success') do

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

