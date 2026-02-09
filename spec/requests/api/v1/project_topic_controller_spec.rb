require 'swagger_helper'

RSpec.describe 'ProjectTopicController API', type: :request do

  def response_body
    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

    # GET /project_topics
    path '/api/v1/project_topics' do
      get('Get project topics') do
        parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
        parameter name: 'topic_ids', in: :query, type: :string, description: 'Topic Identifier', required: false

        tags 'ProjectTopic'
        produces 'application/json'
        response(200, 'successful') do
          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          # context 'when assignment_id parameter is missing' do
          #   let(:assignment) { create(:project_topic, assignment_id: create(:assignment)) }
          #
          #   before { get '/api/v1/project_topics', params: { assignment_id: assignment_id } }
          #   it 'returns an error message with status 422' do
          #     expect(response).to have_http_status(422)
          #     expect(response_body).to eq({ message: 'Assignment ID is required!' })
          #   end
          # end

          context 'when assignment_id parameter is present' do
            let!(:project_topics) { create_list(:project_topic, 3, assignment_id: 1) }
            let(:assignment_id) { 1 }

            context 'when topic_identifier parameter is missing' do
              before { get "/api/v1/project_topics?assignment_id=#{assignment_id}" }

              it 'returns a list of all project topics with the given assignment_id' do
                expect(response).to have_http_status(200)
                #expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
                #expect(response_body[:project_topics].count).to eq(3)
                expect(response).to have_http_status(200)
                expect(JSON.parse(response.body).length).to eq(3)
              end
            end

            context 'when topic_identifier parameter is present' do
              let!(:project_topic) { create(:project_topic, assignment_id: 1, topic_identifier: 'abc') }
              let(:topic_identifier) { 'abc' }

              before { get "/api/v1/project_topics?assignment_id=#{assignment_id}&topic_identifier=#{topic_identifier}" }

              it 'returns a list of project topics with the given assignment_id and topic_identifier' do
                expect(response).to have_http_status(200)
                expect(response_body[:message]).to eq('All selected topics have been loaded successfully.')
                expect(response_body[:project_topics].count).to eq(1)
                expect(response_body[:project_topics].first[:topic_identifier]).to eq('abc')
              end
            end
          end

          run_test!
        end
      end
    end


    # DELETE /project_topics
    path '/api/v1/project_topics' do
      delete('Delete project topics') do
        parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID', required: true
        parameter name: 'topic_ids', in: :query, type: :array, items: { type: :string }, description: 'Topic Identifiers to delete', required: false

        tags 'ProjectTopic'
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

            before { delete '/api/v1/project_topics', params: { assignment_id: assignment_id } }

            it 'returns an error message with status 422' do
              expect(response).to have_http_status(422)
              expect(response_body).to eq({ message: 'Assignment ID is required!' })
            end
          end

          context 'when assignment_id parameter is present' do
            context 'when topic_ids parameter is missing' do
              let(:assignment_id) { 1 }

              before { delete "/api/v1/project_topics?assignment_id=#{assignment_id}" }

              it 'deletes all project topics with the given assignment_id' do
                expect(response).to have_http_status(200)
                #expect(response_body).to eq({ message: 'All project topics have been deleted successfully.' })
                expect(response).to have_http_status(:no_content)
                expect(response.body).to eq("")
                expect(ProjectTopic.where(assignment_id: assignment_id)).to be_empty
              end
            end

            context 'when topic_ids parameter is present' do
              let!(:project_topic) { create(:project_topic, assignment_id: 1, topic_identifier: 'abc') }
              let(:topic_ids) { ['abc'] }
              let(:assignment_id) { 1 }

              before { delete "/api/v1/project_topics?assignment_id=#{assignment_id}&topic_ids=#{topic_ids.join(',')}" }

              it 'deletes project topics with the given assignment_id and topic_identifier' do
                expect(response).to have_http_status(200)
                expect(response_body).to eq({ message: 'All selected topics have been deleted successfully.' })
                expect(ProjectTopic.where(assignment_id: assignment_id, topic_identifier: topic_ids)).to be_empty
              end
            end
          end
        end
      end
    end

    # CREATE /project_topics
    path '/api/v1/project_topics' do
      post('create a new topic in the sheet') do
        tags 'ProjectTopic'
        consumes 'application/json'
        #inputs are from the project topic table with properties as ID, name, choosers
        # assignment ID and micropayment
        parameter name: :project_topic, in: :body, schema: {
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
        let(:valid_attributes) { { project_topic: attributes_for(:project_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before { post '/api/v1/project_topics', params: valid_attributes }

        it 'creates a project topic' do
          expect(response).to have_http_status(:created)
          expect(response_body[:message]).to eq("The topic: \"#{ProjectTopic.last.topic_name}\" has been created successfully.")
        end
      end

      context 'when the request is invalid' do
        let(:invalid_attributes) { { project_topic: { topic_name: '' }, micropayment: 0.1, assignment_id: assignment.id } }

        before { post '/api/v1/project_topics', params: invalid_attributes }

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:message]).to include("Topic name can't be blank")
        end
      end

      context 'when the assignment does not exist' do
        let(:invalid_attributes) { { project_topic: attributes_for(:project_topic), micropayment: 0.1, assignment_id: 999 } }

        before { post '/api/v1/project_topics', params: invalid_attributes }

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:message]).to eq("Couldn't find Assignment with 'id'=999")
        end
      end

      context 'when the assignment is a microtask' do
        let(:valid_attributes) { { project_topic: attributes_for(:project_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before do
          assignment.update(microtask: true)
          post '/api/v1/project_topics', params: valid_attributes
        end

        it 'sets the micropayment' do
          expect(response).to have_http_status(:created)
          expect(ProjectTopic.last.micropayment).to eq(0.1)
        end
      end

      context 'when the assignment is not a microtask' do
        let(:valid_attributes) { { project_topic: attributes_for(:project_topic, assignment_id: assignment.id), micropayment: 0.1 } }

        before do
          assignment.update(microtask: false)
          post '/api/v1/project_topics', params: valid_attributes
        end

        it 'does not set the micropayment' do
          expect(response).to have_http_status(:created)
          expect(ProjectTopic.last.micropayment).to be_nil
        end
      end
    end

    # UPDATE /project_topics
    path '/api/v1/project_topics/{id}' do
      parameter name: 'id', in: :path, type: :integer, description: 'id of the project topic'

      put('update a new topic in the sheet') do
        tags 'ProjectTopic'
        consumes 'application/json'
        parameter name: :project_topic, in: :body, schema: {
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

        let(:project_topic) { create(:project_topic) }
        let(:url) { "/api/v1/project_topics/#{project_topic.id}" }

        context "when valid params are provided" do
          let(:new_topic_name) { "New Topic Name" }
          let(:params) { { project_topic: { topic_name: new_topic_name } } }

          before { put url, params: params }

          it "returns status 200" do
            expect(response).to have_http_status(200)
          end

          it "updates the sign-up topic" do
            project_topic.reload
            expect(project_topic.topic_name).to eq new_topic_name
          end

          it "returns a success message" do
            expect(response.body).to include("has been updated successfully")
          end
        end

        context "when invalid params are provided" do
          let(:params) { { project_topic: { topic_name: "" } } }

          before { put url, params: params }

          it "returns status 422" do
            expect(response).to have_http_status(422)
          end

          it "does not update the sign-up topic" do
            project_topic.reload
            expect(project_topic.topic_name).not_to eq("")
          end

          it "returns an error message" do
            expect(response.body).to include("can't be blank")
          end
        end
      end
      end
    end

