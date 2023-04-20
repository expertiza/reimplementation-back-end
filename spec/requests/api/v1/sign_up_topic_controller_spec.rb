require 'swagger_helper'
#all tests follow a similar json header
#test 1 to check if a topic can be created sucessfully.
# RSpec.describe 'SignUpTopicController API', type: :request do
#   #test 1 to check if a topic can be created sucessfully.
#   path '/api/v1/sign_up_topics' do
#     post('create a new topic in the sheet') do
#       tags 'SignUpTopic'
#       consumes 'application/json'
#       #inputs are from the sign up topic table with properties as ID, name, choosers
#       # assignment ID and micropayment
#       parameter name: :sign_up_topic, in: :body, schema: {
#         type: :object,
#         properties: {
#           topic_identifier: { type: :integer },
#           topic_name: { type: :string },
#           max_choosers: { type: :integer },
#           category: {type: :string},
#           assignment_id: {type: :integer},
#           micropayment: {type: :integer}
#         },
#         #the test will require these inputs to pass
#         required: [ 'topic_identifier', 'topic_name', 'max_choosers', 'category', 'assignment_id','micropayment' ]
#       }
#       response(201, 'Success') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#       response(404, 'Not Found') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#       response(422, 'Invalid Request') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#   end
#   # TEST 2 to update a new topic in the sheet
#   path '/api/v1/sign_up_topics/{id}' do
#     parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'
#     #To update the topic a ID is inputted as a parameter, the topic for this ID must exist
#     # in the database.
#     put('update a new topic in the sheet') do
#       tags 'SignUpTopic'
#       consumes 'application/json'
#       parameter name: :sign_up_topic, in: :body, schema: {
#         type: :object,
#         properties: {
#           topic_identifier: { type: :integer },
#           topic_name: { type: :string },
#           max_choosers: { type: :integer },
#           category: {type: :string},
#           assignment_id: {type: :integer},
#           micropayment: {type: :integer}
#         },
#         required: [ 'topic_identifier', 'topic_name', 'category', 'assignment_id']
#       }
#
#       response(200, 'successful') do
#         let(:id) { '123' }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#       response(404, 'Not Found') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#       response(422, 'Invalid Request') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#   end
#   #test 3 to delete and update a topic
#   path '/api/v1/sign_up_topics/{id}' do
#     parameter name: 'id', in: :path, type: :integer, description: 'id of the sign up topic'
#
#     put('update a new topic in the sheet') do
#       tags 'SignUpTopic'
#       consumes 'application/json'
#       parameter name: :sign_up_topic, in: :body, schema: {
#         type: :object,
#         properties: {
#           topic_identifier: { type: :integer },
#           topic_name: { type: :string },
#           max_choosers: { type: :integer },
#           category: {type: :string},
#           assignment_id: {type: :integer},
#           micropayment: {type: :integer}
#         },
#         required: [ 'topic_identifier', 'topic_name', 'category', 'assignment_id']
#       }
#       response(200, 'successful') do
#         let(:id) { '123' }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#       response(404, 'Not Found') do
#         let(:topic) { { topic_identifier: 1 } }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#     delete('delete sign up topic') do
#
#       tags 'SignUpTopic'
#       response(200, 'successful') do
#         let(:id) { '123' }
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#   end
#   #test 4 - to load topics based on assignment and topic ID.
#   path '/api/v1/sign_up_topics/filter' do
#     get('Get topics based on Assignment ID and Topic Identifiers filter') do
#       parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
#       parameter name: 'topic_ids[]', in: :query, type: :array, description: 'Topic Identifiers', collectionFormat: :multi
#
#       tags 'SignUpTopic'
#       produces 'application/json'
#       response(200, 'successful') do
#
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#     #test 5 - to load topics based on assignment and topic ID.
#     delete('Delete based on Assignment ID and Topic identifier filter') do
#       consumes 'application/json'
#       parameter name: :sign_up_topic, in: :body, schema: {
#         type: :object,
#         properties: {
#           assignment_id: {type: :integer},
#           topic_ids: {
#             type: :array,
#             items: {
#               type: :string
#             }
#           }
#         },
#         required: ['assignment_id']
#       }
#       tags 'SignUpTopic'
#       produces 'application/json'
#       response(200, 'Success') do
#
#         after do |example|
#           example.metadata[:response][:content] = {
#             'application/json' => {
#               example: JSON.parse(response.body, symbolize_names: true)
#             }
#           }
#         end
#         run_test!
#       end
#     end
#   end
#
# end

# describe 'GET /sign_up_topics' do
#   context 'when assignment_id parameter is missing' do
#     before { get '/api/v1/sign_up_topics' }
#
#     it 'returns an error message with status 422' do
#       expect(response).to have_http_status(422)
#       expect(response_body).to eq({ message: 'Assignment ID is required!' })
#     end
#   end
#
#   context 'when assignment_id parameter is present' do
#     let!(:sign_up_topics) { create_list(:sign_up_topic, 3, assignment_id: 1) }
#     let(:assignment_id) { 1 }
#
#     context 'when topic_identifier parameter is missing' do
#       before { get "/api/v1/sign_up_topics?assignment_id=#{assignment_id}" }
#
#       it 'returns a list of all sign-up topics with the given assignment_id' do
#         expect(response).to have_http_status(200)
#         expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
#         expect(response_body[:sign_up_topics].count).to eq(3)
#       end
#     end
#
#     context 'when topic_identifier parameter is present' do
#       let!(:sign_up_topic) { create(:sign_up_topic, assignment_id: 1, topic_identifier: 'abc') }
#       let(:topic_identifier) { 'abc' }
#
#       before { get "/api/v1/sign_up_topics?assignment_id=#{assignment_id}&topic_identifier=#{topic_identifier}" }
#
#       it 'returns a list of sign-up topics with the given assignment_id and topic_identifier' do
#         expect(response).to have_http_status(200)
#         expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
#         expect(response_body[:sign_up_topics].count).to eq(1)
#         expect(response_body[:sign_up_topics].first[:topic_identifier]).to eq('abc')
#       end
#     end
#   end
# end
RSpec.describe 'SignUpTopicController API', type: :request do
  # GET /sign_up_topics
  path '/api/v1/sign_up_topics' do
    get('Get sign-up topics') do
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
      parameter name: 'topic_identifier', in: :query, type: :string, description: 'Topic Identifier', required: false

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

        context 'when assignment_id parameter is missing' do
          let(:assignment_id) { nil }

          before { get '/api/v1/sign_up_topics', params: { assignment_id: assignment_id } }

          it 'returns an error message with status 422' do
            expect(response).to have_http_status(422)
            expect(response_body).to eq({ message: 'Assignment ID is required!' })
          end
        end

        context 'when assignment_id parameter is present' do
          let!(:sign_up_topics) { create_list(:sign_up_topic, 3, assignment_id: 1) }
          let(:assignment_id) { 1 }

          context 'when topic_identifier parameter is missing' do
            before { get "/api/v1/sign_up_topics?assignment_id=#{assignment_id}" }

            it 'returns a list of all sign-up topics with the given assignment_id' do
              expect(response).to have_http_status(200)
              expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
              expect(response_body[:sign_up_topics].count).to eq(3)
            end
          end

          context 'when topic_identifier parameter is present' do
            let!(:sign_up_topic) { create(:sign_up_topic, assignment_id: 1, topic_identifier: 'abc') }
            let(:topic_identifier) { 'abc' }

            before { get "/api/v1/sign_up_topics?assignment_id=#{assignment_id}&topic_identifier=#{topic_identifier}" }

            it 'returns a list of sign-up topics with the given assignment_id and topic_identifier' do
              expect(response).to have_http_status(200)
              expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
              expect(response_body[:sign_up_topics].count).to eq(1)
              expect(response_body[:sign_up_topics].first[:topic_identifier]).to eq('abc')
            end
          end
        end

        run_test!
      end
    end
  end

  # DELETE /sign_up_topics
  path '/api/v1/sign_up_topics' do
    delete('Delete sign-up topics') do
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
      parameter name: 'topic_ids', in: :query, type: :array, items: { type: :string }, description: 'Topic Identifiers to delete', required: false

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

        context 'when assignment_id parameter is missing' do
          let(:assignment_id) { nil }

          before { delete '/api/v1/sign_up_topics', params: { assignment_id: assignment_id } }

          it 'returns an error message with status 422' do
            expect(response).to have_http_status(422)
            expect(response_body).to eq({ message: 'Assignment ID is required!' })
          end
        end

        context 'when assignment_id parameter is present' do
          context 'when topic_ids parameter is missing' do
            let(:assignment_id) { 1 }

            before { delete "/api/v1/sign_up_topics?assignment_id=#{assignment_id}" }

            it 'deletes all sign-up topics with the given assignment_id' do
              expect(response).to have_http_status(200)
              expect(response_body).to eq({ message: 'All sign-up topics have been deleted successfully.' })
              expect(SignUpTopic.where(assignment_id: assignment_id)).to be_empty
            end
          end

          context 'when topic_ids parameter is present' do
            let!(:sign_up_topic) { create(:sign_up_topic, assignment_id: 1, topic_identifier: 'abc') }
            let(:topic_ids) { ['abc'] }
            let(:assignment_id) { 1 }

            before { delete "/api/v1/sign_up_topics?assignment_id=#{assignment_id}&topic_ids=#{topic_ids.join(',')}" }

            it 'deletes sign-up topics with the given assignment_id and topic_identifier' do
              expect(response).to have_http_status(200)
              expect(response_body).to eq({ message: 'All selected topics have been deleted successfully.' })
              expect(SignUpTopic.where(assignment_id: assignment_id, topic_identifier: topic_ids)).to be_empty
            end
          end
        end
      end
    end
  end

end