require 'swagger_helper'

RSpec.describe 'SignUpTopicController API', type: :request do

    # GET /sign_up_topics
    path '/api/v1/sign_up_topics' do
      get('Get sign-up topics') do
        parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
        parameter name: 'topic_ids', in: :query, type: :string, description: 'Topic Identifier', required: false

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

    # CREATE /sign_up_topics
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
            category: { type: :string },
            assignment_id: { type: :integer },
            micropayment: { type: :integer }
          },
          #the test will require these inputs to pass
          required: %w[topic_identifier topic_name max_choosers category assignment_id micropayment]
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
      end

      let!(:assignment) { create(:assignment) }

      context 'when the request is valid' do
        let(:valid_attributes) { { sign_up_topic: attributes_for(:sign_up_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before { post '/api/v1/sign_up_topics', params: valid_attributes }

        it 'creates a sign-up topic' do
          expect(response).to have_http_status(:created)
          expect(response_body[:message]).to eq("The topic: \"#{SignUpTopic.last.topic_name}\" has been created successfully.")
        end
      end

      context 'when the request is invalid' do
        let(:invalid_attributes) { { sign_up_topic: { topic_name: '' }, micropayment: 0.1, assignment_id: assignment.id } }

        before { post '/api/v1/sign_up_topics', params: invalid_attributes }

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:message]).to include("Topic name can't be blank")
        end
      end

      context 'when the assignment does not exist' do
        let(:invalid_attributes) { { sign_up_topic: attributes_for(:sign_up_topic), micropayment: 0.1, assignment_id: 999 } }

        before { post '/api/v1/sign_up_topics', params: invalid_attributes }

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:message]).to eq("Couldn't find Assignment with 'id'=999")
        end
      end

      context 'when the assignment is a microtask' do
        let(:valid_attributes) { { sign_up_topic: attributes_for(:sign_up_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before do
          assignment.update(microtask: true)
          post '/api/v1/sign_up_topics', params: valid_attributes
        end

        it 'sets the micropayment' do
          expect(response).to have_http_status(:created)
          expect(SignUpTopic.last.micropayment).to eq(0.1)
        end
      end

      context 'when the assignment is not a microtask' do
        let(:valid_attributes) { { sign_up_topic: attributes_for(:sign_up_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before do
          assignment.update(microtask: false)
          post '/api/v1/sign_up_topics', params: valid_attributes
        end

        it 'does not set the micropayment' do
          expect(response).to have_http_status(:created)
          expect(SignUpTopic.last.micropayment).to be_nil
        end
      end
    end

    # UPDATE /sign_up_topics
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
            category: { type: :string },
            assignment_id: { type: :integer },
            micropayment: { type: :integer }
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

        let(:sign_up_topic) { create(:sign_up_topic) }
        let(:url) { "/api/v1/sign_up_topics/#{sign_up_topic.id}" }

        context "when valid params are provided" do
          let(:new_topic_name) { "New Topic Name" }
          let(:params) { { sign_up_topic: { topic_name: new_topic_name } } }

          before { put url, params: params }

          it "returns status 200" do
            expect(response).to have_http_status(200)
          end

          it "updates the sign-up topic" do
            sign_up_topic.reload
            expect(sign_up_topic.topic_name).to eq new_topic_name
          end

          it "returns a success message" do
            expect(response.body).to include("has been updated successfully")
          end
        end

        context "when invalid params are provided" do
          let(:params) { { sign_up_topic: { topic_name: "" } } }

          before { put url, params: params }

          it "returns status 422" do
            expect(response).to have_http_status(422)
          end

          it "does not update the sign-up topic" do
            sign_up_topic.reload
            expect(sign_up_topic.topic_name).not_to eq("")
          end

          it "returns an error message" do
            expect(response.body).to include("can't be blank")
          end
        end
      end
      end
    end

