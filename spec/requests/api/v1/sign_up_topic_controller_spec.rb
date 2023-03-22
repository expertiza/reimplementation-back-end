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
       #the test will require these inputs to pass
       required: [ 'topic_identifier', 'topic_name', 'max_choosers', 'category', 'assignment_id','micropayment' ]
     }
     #a success is generated if the testing is successfull
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
  #test 3 to delete and update a topic
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
    #inputs the topic to be deleted as a unique ID and deletes it from the DB
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
  # test 4 - takes in two parameter arguments and checks if the entries are present
  path '/api/v1/sign_up_topics/load_all_selected_topics' do
    get('list the topics') do
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID'
      parameter name: 'topic_ids', in: :query, type: :integer, description: 'Topic ID'
      # consumes 'application/json'
      # parameter name: :sign_up_topic, in: :body, schema: {
      #   type: :object,
      #   properties: {
      #     assignment_id: {type: :integer},
      #     topic_identifier: { type: :integer }
      #   }
      # }
      tags 'SignUpTopic'
      produces 'application/json'
      response(200, 'successful') do
        #if entries are present it sucessfully spills them in the api test
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
  # test 5 to delete all selected topics
  path '/api/v1/sign_up_topics/delete_all_selected_topics' do
    delete('test for all selected topics') do
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: {type: :integer},
          topic_ids: { type: :integer }
        }
      }
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
  #test 6 mass delete topics based on assignment.
  path '/api/v1/sign_up_topics/delete_all_topics_for_assignment' do
    delete('test to delete topics') do
      consumes 'application/json'
      parameter name: :sign_up_topic, in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: {type: :integer}
        }
      }
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