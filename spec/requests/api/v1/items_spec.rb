# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength, Layout/LineLength

require 'swagger_helper'
require 'json_web_token'
# Rspec tests for items controller
RSpec.describe 'items', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) do
    User.create(
      name: 'profa',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Prof A',
      email: 'testuser@example.com',
      mru_directory_path: '/home/testuser'
    )
  end

  let!(:questionnaire) do
    instructor
    Questionnaire.create(
      name: 'Questionnaire 1',
      questionnaire_type: 'AuthorFeedbackReview',
      private: true,
      min_question_score: 0,
      max_question_score: 10,
      instructor_id: instructor.id
    )
  end

  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }
  path '/items' do
    let(:item1) do
      questionnaire
      Item.create(
        seq: 1,
        prompt: 'test item 1',
        item_type: 'multiple_choice',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:item2) do
      questionnaire
      Item.create(
        seq: 2,
        prompt: 'test item 2',
        item_type: 'multiple_choice',
        break_before: false,
        weight: 10,
        questionnaire: questionnaire
      )
    end

    # get request on /items returns 200 successful response when it returns list of items present in the database
    get('list items') do
      tags 'Items'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post('create item') do
      tags 'Items'
      consumes 'application/json'
      produces 'application/json'

      let(:valid_item_params) do
        {
          questionnaire_id: questionnaire.id,
          prompt: 'test item',
          item_type: 'multiple_choice',
          break_before: false,
          seq: 1,
          weight: 10
        }
      end
      # Creation of dummy objects for the test with the help of let statements
      let(:invalid_item_params1) do
        {
          questionnaire_id: nil,
          prompt: 'test item',
          item_type: 'multiple_choice',
          break_before: false,
          weight: 10
        }
      end

      let(:invalid_item_params2) do
        {
          questionnaire_id: questionnaire.id,
          prompt: 'test item',
          item_type: nil,
          break_before: false,
          weight: 10
        }
      end

      parameter name: :item, in: :body, schema: {
        type: :object,
        properties: {
          weight: { type: :integer },
          questionnaire_id: { type: :integer },
          break_before: { type: :boolean },
          prompt: { type: :string },
          item_type: { type: :string },
          seq: { type: :number }
        },
        required: %w[weight questionnaire_id break_before prompt item_type seq]
      }

      # post request on /items returns 201 created response and creates a item with given valid parameters
      response(201, 'created') do
        let(:item) { valid_item_params }
        run_test! do
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['seq'].to_i).to eq(1)
        end
      end

      # post request on /items returns 404 not found when questionnaire id for the given item is not present in the database
      response(404, 'questionnaire id not found') do
        let(:item) do
          instructor
          Item.create(invalid_item_params1)
        end
        run_test!
      end

      # post request on /items returns 422 unprocessable entity when incorrect parameters are passed to create a item
      response(422, 'unprocessable entity') do
        let(:item) { invalid_item_params2 } # <--- pass invalid params directly to the request
        run_test!
      end
    end
  end

  path '/items/{id}' do
    parameter name: 'id', in: :path, type: :integer

    let(:item1) do
      questionnaire
      Item.create(
        seq: 1,
        prompt: 'test item 1',
        item_type: 'Scale',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:item2) do
      questionnaire
      Item.create(
        seq: 2,
        prompt: 'test item 2',
        item_type: 'Scale',
        break_before: false,
        weight: 10,
        questionnaire: questionnaire
      )
    end

    let(:id) do
      questionnaire
      item1
      item1.id
    end

    get('show item') do
      tags 'Items'
      produces 'application/json'

      # get request on /items/{id} returns 200 successful response and returns item with given item id
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include('"prompt":"test item 1"')
        end
      end

      # get request on /items/{id} returns 404 not found response when item id is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
        run_test! do
          expect(response.body).to include("Couldn't find Item")
        end
      end
    end

    put('update item') do
      tags 'Items'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          break_before: { type: :boolean },
          seq: { type: :integer }
        }
      }

      # put request on /items/{id} returns 200 successful response and updates parameters of item with given item id
      response(200, 'successful') do
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include('"break_before":true')
        end
      end

      # put request on /items/{id} returns 404 not found response when item with given id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include('Not Found')
        end
      end

      # put request on /items/{id} returns 422 unprocessable entity when incorrect parameters are passed for item with given item id
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            seq: 'Dfsd'
          }
        end
        schema type: :object
        run_test! do
          expect(response.body).to_not include('"seq":"Dfsd"')
        end
      end
    end

    patch('update item') do
      tags 'Items'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          break_before: { type: :boolean },
          seq: { type: :integer }
        }
      }

      # patch request on /items/{id} returns 200 successful response and updates parameters of item with given item id
      response(200, 'successful') do
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include('"break_before":true')
        end
      end

      # patch request on /items/{id} returns 404 not found response when item with given id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            break_before: true
          }
        end
        run_test! do
          expect(response.body).to include("Couldn't find Item")
        end
      end

      # patch request on /items/{id} returns 422 unprocessable entity when incorrect parameters are passed for item with given item id
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            seq: 'Dfsd'
          }
        end
        schema type: :object
        run_test! do
          expect(response.body).to_not include('"seq":"Dfsd"')
        end
      end
    end

    delete('delete item') do
      tags 'Items'
      produces 'application/json'

      # delete request on /items/{id} returns 204 successful response when it deletes item with given item id present in the database
      response(204, 'successful') do
        run_test! do
          expect(Item.exists?(id)).to eq(false)
        end
      end

      # delete request on /items/{id} returns 404 not found response when item with given item id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Item")
        end
      end
    end
  end

  path '/items/delete_all/questionnaire/{id}' do
    parameter name: 'id', in: :path, type: :integer

    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:item1) do
      questionnaire
      Item.create(
        seq: 1,
        prompt: 'test item 1',
        item_type: 'multiple_choice',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:item2) do
      questionnaire
      Item.create(
        seq: 2,
        prompt: 'test item 2',
        item_type: 'multiple_choice',
        break_before: false,
        weight: 10,
        questionnaire: questionnaire
      )
    end

    let(:id) do
      questionnaire
      item1
      item2
      questionnaire.id
    end

    delete('delete all items') do
      tags 'Items'
      produces 'application/json'

      # delete method on /items/delete_all/questionnaire/{id} returns 200 successful response when all items with given questionnaire id are deleted
      response(200, 'successful') do
        run_test! do
          expect(Item.where(questionnaire_id: id).count).to eq(0)
        end
      end

      # delete request on /items/delete_all/questionnaire/{id} returns 404 not found response when questionnaire id is not found in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/items/show_all/questionnaire/{id}' do
    parameter name: 'id', in: :path, type: :integer

    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:item1) do
      questionnaire
      Item.create(
        seq: 1,
        prompt: 'test item 1',
        item_type: 'multiple_choice',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:questionnaire2) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 2',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:item2) do
      questionnaire2
      Item.create(
        seq: 2,
        prompt: 'test item 2',
        item_type: 'multiple_choice',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire2
      )
    end

    let(:item3) do
      questionnaire2
      Item.create(
        seq: 3,
        prompt: 'test item 3',
        item_type: 'multiple_choice',
        break_before: false,
        weight: 10,
        questionnaire: questionnaire2
      )
    end

    let(:id) do
      questionnaire
      questionnaire2
      item1
      item2
      item3
      questionnaire.id
    end

    get('show all items') do
      tags 'Items'
      produces 'application/json'

      # get method on /items/show_all/questionnaire/{id} returns 200 successful response when all items with given questionnaire id are shown
      response(200, 'successful') do
        run_test! do
          expect(Item.where(questionnaire_id: id).count).to eq(1)
          expect(response.body).to_not include("\"questionnaire_id: \"#{questionnaire2.id}")
        end
      end

      # get request on /items/delete_all/questionnaire/{id} returns 404 not found response when questionnaire id is not found in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Questionnaire")
        end
      end
    end
  end

  path '/items/types' do
    let(:questionnaire) do
      instructor
      Questionnaire.create(
        name: 'Questionnaire 1',
        questionnaire_type: 'AuthorFeedbackReview',
        private: true,
        min_question_score: 0,
        max_question_score: 10,
        instructor_id: instructor.id
      )
    end

    let(:item1) do
      questionnaire
      Item.create(
        seq: 1,
        prompt: 'test item 1',
        item_type: 'multiple_choice',
        break_before: true,
        weight: 5,
        questionnaire: questionnaire
      )
    end

    let(:item2) do
      questionnaire
      Item.create(
        seq: 2,
        prompt: 'test item 2',
        item_type: 'multiple_choice',
        break_before: false,
        weight: 10,
        questionnaire: questionnaire
      )
    end

    get('item types') do
      tags 'Items'
      produces 'application/json'
      # get request on /items/types returns types of items present in the database
      response(200, 'successful') do
        run_test! do
          parsed_response = JSON.parse(response.body)
          expect(parsed_response.size).to eq(7)
          expect(parsed_response).to include('Multiple choice')
        end
      end
    end
  end
end
