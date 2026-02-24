require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'ProjectTopicController API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "Instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({id: instructor.id}) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:assignment1) { Assignment.create!(name: 'Test Assignment 1', instructor_id: instructor.id) }
  let!(:assignment2) { Assignment.create!(name: 'Test Assignment 2', instructor_id: instructor.id, microtask: true) }

  def response_body
    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

    # GET /project_topics
    path '/project_topics' do
      get('Get project topics') do
        parameter name: :assignment_id, in: :query, type: :integer, required: true
        parameter name: :topic_identifier, in: :query, type: :string, required: false

        tags 'ProjectTopic'
        produces 'application/json'

        response(200, 'successful') do

          let!(:project_topics) { create_list(:project_topic, 3, assignment_id: assignment1.id) }
          let(:assignment_id) { assignment1.id }

          context 'when topic_identifier is missing' do
            run_test! do |response|
              body = JSON.parse(response.body)
              expect(body.length).to eq(3)
            end
          end

          context 'when topic_identifier is present' do
            let!(:project_topic) { create(:project_topic, assignment_id: assignment1.id, topic_identifier: 'abc') }
            let(:topic_identifier) { 'abc' }

            run_test! do |response|
              body = JSON.parse(response.body)
              expect(body.length).to eq(4)
              expect(body.last['topic_identifier']).to eq('abc')
            end
          end
        end
      end
    end

    # DELETE /project_topics
    path '/project_topics' do
      delete('Delete project topics') do
        parameter name: 'assignment_id', in: :query, type: :integer, description: 'Assignment ID'
        parameter name: 'topic_ids', in: :query, type: :array, items: { type: :string }, description: 'Topic Identifiers to delete', required: false
        parameter name: :Authorization, in: :header

        tags 'ProjectTopic'
        produces 'application/json'
          # after do |example|
          #   example.metadata[:response][:content] = {
          #     'application/json' => {
          #       example: JSON.parse(response.body, symbolize_names: true)
          #     }
          #   }
          # end

          response(422,'when assignment_id parameter is missing') do
            let(:assignment_id) { nil }

            run_test! do |response|
              expect(response_body).to eq({ message: 'Assignment ID is required!' })
            end
          end

          response(204, 'when assignment_id parameter is present but topic_ids parameter is missing') do
              let(:assignment_id) { assignment1.id }
              let!(:project_topics) { create_list(:project_topic, 3, assignment_id: assignment1.id) }

              run_test! do |response|
                expect(response).to have_http_status(:no_content)
                expect(response.body).to eq("")
                expect(ProjectTopic.where(assignment_id: assignment_id)).to be_empty
              end

            response(204, 'when topic_ids parameter is present') do
              let!(:project_topic) { create(:project_topic, assignment_id: assignment1.id, topic_identifier: 'abc') }
              let(:topic_ids) { ['abc'] }
              let(:assignment_id) { assignment1.id }


              run_test! do |response|
                expect(response).to have_http_status(:no_content)
                expect(response.body).to eq("")
                expect(ProjectTopic.where(assignment_id: assignment_id, topic_identifier: topic_ids)).to be_empty
              end
            end
          end
      end
    end

    # CREATE /project_topics
    path '/project_topics' do
      post('create a new topic in the sheet') do
        tags 'ProjectTopic'
        consumes 'application/json'
        #inputs are from the project topic table with properties as ID, name, choosers, assignment ID and micropayment
        parameter name: :project_topic, in: :body, schema: {
          type: :object,
          properties: {
            topic_identifier: { type: :string },
            topic_name: { type: :string },
            max_choosers: { type: :integer },
            category: { type: :string },
            assignment_id: { type: :integer },
            micropayment: { type: :integer }
          },
          #the test will require these inputs to pass
          required: %w[topic_identifier topic_name max_choosers category assignment_id micropayment]
        }
        # response(201, 'Success') do
        #   let(:project_topic) { { topic_identifier: 1 } }
        #   after do |example|
        #     example.metadata[:response][:content] = {
        #       'application/json' => {
        #         example: JSON.parse(response.body, symbolize_names: true)
        #       }
        #     }
        #   end
        #   run_test!
        # end
      

        response(201, 'when the request is valid') do
          let(:project_topic) do
            {
              topic_identifier: 'abc',
              topic_name: 'Topic ABC',
              max_choosers: 3,
              category: 'quiz',
              assignment_id: assignment1.id,
              micropayment: 2
            }
          end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:created)
            expect(response_json["message"]).to eq("The topic: \"#{ProjectTopic.last.topic_name}\" has been created successfully.")
          end
        end

        response(422, 'when the request is invalid') do
          let(:project_topic) do { topic_name: '', micropayment: 1, assignment_id: assignment1.id }  end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_json["message"]["topic_name"].first).to eq("can't be blank")
          end
        end

        response(422, 'when the assignment does not exist') do
          let(:project_topic) do {  topic_identifier: 'abc', topic_name: 'Topic ABC', max_choosers: 3, category: 'quiz', micropayment: 5, assignment_id: 999} end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_json["message"]["assignment"].first).to include("must exist")
          end
        end

        response(201, 'when the assignment is a microtask') do
          let(:project_topic) do { topic_identifier: 'xyz', topic_name: 'Topic XYZ', max_choosers: 2, category: 'review', assignment_id: assignment2.id, micropayment: 1 } end           

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:created)
            expect(response_json["message"]).to eq("The topic: \"#{ProjectTopic.last.topic_name}\" has been created successfully.")
            expect(ProjectTopic.last.micropayment).to eq(1)
          end
        end

        response(201, 'when the assignment is not a microtask') do
          let(:project_topic) do { topic_identifier: 'qwe', topic_name: 'Topic QWE', max_choosers: 1, category: 'review',assignment_id: assignment1.id, micropayment: 5 } end

          run_test! do |response|
            expect(response).to have_http_status(:created)
            expect(ProjectTopic.last.micropayment).to eq(0)
          end
        end
     
      end
    end

    # # UPDATE /project_topics
    path '/project_topics/{id}' do
      parameter name: 'id', in: :path, type: :integer, description: 'ID of the project topic'

      put('update a topic in the sheet') do
        tags 'ProjectTopic'
        consumes 'application/json'

        parameter name: :project_topic, in: :body, schema: {
          type: :object,
          properties: {
            topic_identifier: { type: :string },
            topic_name: { type: :string },
            max_choosers: { type: :integer },
            category: { type: :string },
            assignment_id: { type: :integer },
            micropayment: { type: :integer }
          },
          required: %w[topic_identifier topic_name category assignment_id]
        }

        let!(:existing_topic) { create(:project_topic) }
        let!(:project_topic_2) { create(:project_topic, assignment_id: assignment2.id) }
        let(:id) { existing_topic.id }

        response(200, 'when the request is valid') do
          let(:project_topic) do
            {
              topic_identifier: 'updated123',
              topic_name: 'Updated Topic Name',
              max_choosers: 5,
              category: 'updated_category',
              assignment_id: assignment1.id,
              micropayment: 3
            }
          end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:ok)
            expect(response_json["message"]).to eq("The topic: \"#{existing_topic.reload.topic_name}\" has been updated successfully.")
            expect(existing_topic.topic_name).to eq('Updated Topic Name')
          end
        end

        response(422, 'when the request is invalid') do
          let(:project_topic) do
            {
              topic_identifier: 'updated123',
              topic_name: '',
              category: 'quiz',
              assignment_id: assignment1.id
            }
          end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_json["message"]["topic_name"].first).to eq("can't be blank")
          end
        end

        response(422, 'when the assignment does not exist') do          
          let(:project_topic) do
            {
              topic_identifier: 'updated123',
              topic_name: 'Updated Topic',
              category: 'quiz',
              assignment_id: 999
            }
          end

          run_test! do |response|
            response_json = JSON.parse(response.body)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_json["message"]["assignment"].first).to include("must exist")
          end
        end

        response(200, 'when the assignment is a microtask') do
          let(:id) { project_topic_2.id }
          let(:project_topic) do { micropayment: 4 }end

          run_test! do |response|
            expect(response).to have_http_status(:ok)
            expect(project_topic_2.reload.micropayment).to eq(4)
          end
        end

        response(200, 'when the assignment is not a microtask') do
          let(:project_topic) do
            {
              topic_identifier: 'normal123',
              topic_name: 'Normal Updated',
              category: 'review',
              assignment_id: assignment1.id,
              micropayment: 10
            }
          end

          run_test! do |response|
            expect(response).to have_http_status(:ok)
            expect(existing_topic.reload.micropayment).to eq(0)
          end
        end

      end
    end
  end
