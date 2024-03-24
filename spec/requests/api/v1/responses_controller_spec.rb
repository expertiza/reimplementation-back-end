require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Responses API Controller', type: :request do
  let(:user) { User.new(name: 'Smith') }
  let(:auth_token) { authenticate_user(user) } # This should be obtained or mocked according to your auth system

  let(:headers) { { 'Authorization': "Bearer #{auth_token}" } }

  let(:params) do
    {
      map_id: 1,
      additional_comment: 'This is a sample comment',
      is_submitted: false,
      version_num: 1,
      round: 2,
      visibility: 'private',
      response_map: {
        id: 1,
        reviewed_object_id: 1,
        reviewer_id: 1,
        reviewee_id: 2,
        type: 'ReviewResponseMap',
        calibrate_to: false,
        team_reviewing_enabled: false,
        assignment_questionnaire_id: 1
      },
      scores: [
        { question_id: 1, answer: 5, comments: 'Answer 1 comments' },
        { question_id: 2, answer: 4, comments: 'Answer 2 comments' },
        { question_id: 3, answer: 3, comments: 'Answer 3 comments' }
      ]
    }
  end

  path '/api/v1/responses' do
    get('list responses') do
      tags 'Responses'
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
    post('create response') do
      tags 'Responses'
      consumes 'application/json'
      parameter name: :response, in: :body, schema: {
        type: :object,
        properties: {
          map_id: { type: :integer },
          additional_comment: { type: :text },
          is_submitted: { type: :boolean },
          version_num: { type: :integer },
          round: { type: :integer },
          visibility: { type: :string },
          response_map: {
            id: { type: :integer },
            reviewed_object_id: { type: :integer },
            reviewer_id: { type: :integer },
            reviewee_id: { type: :integer },
            type: { type: :string },
            calibrate_to: { type: :boolean },
            team_reviewing_enabled: { type: :boolean },
            assignment_questionnaire_id: { type: :integer }
          },
          scores: [
            {
              id: { type: :integer },
              answer: { type: :integer },
              comments: { type: :text },
              question_id: { type: :integer },
              question: {
                id: { type: :integer },
                txt: { type: :integer }
              }
            }

          ]
        },
        required: ['map_id']
      }
      response(201, 'Created a response') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      end

      # response(422, 'invalid request') do
      #   let(:response) { { map_id: nil } }
      #
      #   after do |example|
      #     example.metadata[:response][:content] = {
      #       'application/json' => {
      #         example: JSON.parse(response.body, symbolize_names: true)
      #       }
      #     }
      #   end
      #   run_test!
      # end
      # end

      # context 'When the request is valid' do
      #   let(:valid_attributes) { { response: params } }
      #   before { post '/api/v1/responses', params: valid_attributes, headers: headers }
      #
      #   it 'creates a responce' do
      #
      #     expect(response).to have_http_status(:created)
      #     expect(response_body[:message]).to eq("Your response id #{Response.last.id} was successfully saved.")
      #   end
      # end
    end
  end

  path '/api/vi/responses/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the response'

    get('show response') do
      tags 'Responses'
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

    patch('update response') do
      tags 'Responses'
      consumes 'application/json'
      parameter name: :response, in: :body, schema: {
        type: :object,
        properties: {
          id: {type: :integer},
          map_id: {type: :integer},
          additional_comment: {type: :text},
          is_submitted: { type: :boolean},
          version_num: { type: :integer},
          round: { type: :integer},
          visibility: { type: :string},
          response_map: {
            id: {type: :integer},
            reviewed_object_id: {type: :integer},
            reviewer_id: {type: :integer},
            reviewee_id: {type: :integer},
            type: {type: :string},
            calibrate_to: {type: :boolean},
            team_reviewing_enabled: {type: :boolean},
            assignment_questionnaire_id: {type: :integer}
          },
          scores: [
            {
              id: {type: :integer},
              answer: {type: :integer},
              comments: {type: :text},
              question_id: {type: :integer},
              question: {
                id: {type: :integer},
                txt: {type: :integer}
              }
            }

          ]
        },
        required: [ 'name' ]
      }

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
        let(:response) { { id: '' } }
        let(:id) { create(:response).id }

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
    put('update response') do
      tags 'Responses'
      consumes 'application/json'
      parameter name: :response, in: :body, schema: {
        type: :object,
        properties: {
          id: {type: :integer},
          map_id: {type: :integer},
          additional_comment: {type: :text},
          is_submitted: { type: :boolean},
          version_num: { type: :integer},
          round: { type: :integer},
          visibility: { type: :string},
          response_map: {
            id: {type: :integer},
            reviewed_object_id: {type: :integer},
            reviewer_id: {type: :integer},
            reviewee_id: {type: :integer},
            type: {type: :string},
            calibrate_to: {type: :boolean},
            team_reviewing_enabled: {type: :boolean},
            assignment_questionnaire_id: {type: :integer}
          },
          scores: [
            {
              id: {type: :integer},
              answer: {type: :integer},
              comments: {type: :text},
              question_id: {type: :integer},
              question: {
                id: {type: :integer},
                txt: {type: :integer}
              }
            }

          ]
        },
        required: [ 'name' ]
      }

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
        let(:response) { { id: '' } }
        let(:id) { create(:response).id }

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
