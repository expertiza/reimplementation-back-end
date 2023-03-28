require 'swagger_helper'


RSpec.describe 'Responses API', type: :request do

  path '/api/v1/responses' do
    post('create response') do 
      parameter name: 'id', in: :query, type: :string, description: 'Response Map ID', required: true

      # let(:response_map) {[instance_double(ResponseMap)]}

      let(:id) { "1" }

      random = double(id: 1)
      before do
        # response_map_instance = instance_double(ResponseMap)

      allow(ResponseMap).to receive(:find).with(id).and_return(random)
        
      end

      tags 'Responses'
        parameter name: :response, in: :body, schema: {
         type: :object,
         properties: {
          #  id: { type: :integer },
          map_id: { type: :integer},
          additional_comment: {type: :text},
          created_at: { type: :string, format: :date_time },
          updated_at: { type: :string, format: :date_time },
          version_num: {type: :integer},
          round: {type: :integer},
          is_submitted: {type: :boolean},
          visibility: {type: :string},
        }
        #  required: [ 'response' ]
       }
       response(201, 'Created a response') do
        let(:response) { { map_id: 1, additional_comment: "a comment", version_num: 1, round: 1, is_submitted: false, visibility: "idk" } }
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
  
    delete('delete Response') do
      tags 'Responses'

      parameter name: 'id', in: :query, type: :string, description: 'Response Map ID', required: true

      # let(:response_map) {[instance_double(ResponseMap)]}

      let(:id) { "1" }

      before do
        response_map_instance = instance_double(ResponseMap)

        # response_map_instance.id = 1
        allow(ResponseMap).to receive(:find).with(id).and_return(response_map_instance)
        
      end

      # parameter name: :id, in: :body, schema: {
      #    type: :object,
      #    properties: {
      #     #  id: { type: :integer },
      #     map_id: { type: :integer},
      #     additional_comment: {type: :text},
      #     created_at: { type: :string, format: :date_time },
      #     updated_at: { type: :string, format: :date_time },
      #     version_num: {type: :integer},
      #     round: {type: :integer},
      #     is_submitted: {type: :boolean},
      #     visibility: {type: :string},
      #   },
      #    required: [ 'id' ]
      #  }
      response(200, 'successful') do
        let(:assignment) { build(:assignment, instructor_id: 6, id: 1) }
        let(:instructor) { build(:instructor, id: 6) }
        let(:participant) { build(:participant, id: 1, user_id: 6, assignment: assignment) }   
        let(:review_response_map) { build(:review_response_map, id: 1, reviewer: participant)}
        let(:id) { 1 }
  

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
