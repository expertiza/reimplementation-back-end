require 'swagger_helper'

# Rspec test for Bookmarks Controller
RSpec.describe 'api/v1/bookmarks', type: :request do

  path '/api/v1/bookmarks' do

    # Creation of dummy objects for the test with the help of let statements
    let(:user) { User.create(email: 'test@test.com', password: 'password') }
    let(:bookmark1) do
      user
      Bookmark.create(
        url: 'http://example.com',
        title: 'Example Bookmark',
        description: 'An example bookmark',
        topic_id: 1,
        rating: 5,
        user_id: user.id
      )
    end

    let(:bookmark2) do
      user
      Bookmark.create(
        url: 'http://example2.com',
        title: 'Example Bookmark 2',
        description: 'Another example bookmark',
        topic_id: 2,
        rating: 4,
        user_id: user.id
      )
    end

    # get request on /api/v1/bookmarks return list of bookmarks with response 200
    get('list bookmarks') do
      tags 'Bookmarks'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post('create bookmark') do
      tags 'Bookmarks'
      let(:user) { User.create(email: 'test@test.com', password: '123456') }
      let(:valid_bookmark_params) do
        {
          url: 'http://example.com',
          title: 'Example Bookmark',
          description: 'An example bookmark',
          topic_id: 1,
          rating: 5
        }
      end

      let(:invalid_bookmark_params) do
        {
          url: nil, # invalid url
          title: 'Example Bookmark',
          description: 'An example bookmark',
          topic_id: 1,
          rating: 5
        }
      end

      consumes 'application/json'
      produces 'application/json'
      parameter name: :bookmark, in: :body, schema: {
        type: :object,
        properties: {
          url: { type: :string },
          title: { type: :string },
          description: { type: :string },
          topic_id: { type: :integer },
          rating: { type: :integer }
        },
        required: %w[url title description topic_id rating]
      }

      # post request on /api/v1/bookmarks creates bookmark with response 201 when correct params are passed
      response(201, 'created') do
        let(:bookmark) do
          user
          Bookmark.create(valid_bookmark_params)
        end
        run_test! do
          expect(response.body).to include('"title":"Example Bookmark"')
        end
      end

      # post request on /api/v1/bookmarks returns 422 response - unprocessable entity when wrong params is passed to create bookmark
      response(422, 'unprocessable entity') do
        let(:bookmark) do
          user
          Bookmark.create(invalid_bookmark_params)
        end
        run_test!
      end
    end

  end

  path '/api/v1/bookmarks/{id}' do
    parameter name: 'id', in: :path, type: :integer

    # Creation of dummy objects for the test with the help of let statements
    let(:user) { User.create(email: 'test@test.com', password: '123456') }
    let(:valid_bookmark_params) do
      {
        url: 'http://example.com',
        title: 'Example Bookmark',
        description: 'An example bookmark',
        topic_id: 1,
        rating: 5,
        user_id: user.id
      }
    end

    let(:bookmark) do
      user
      Bookmark.create(valid_bookmark_params)
    end

    let(:id) do
      bookmark
      bookmark.id
    end

    # Get request on /api/v1/bookmarks/{id} returns the response 200 succesful - bookmark with id = {id} when correct id is passed which is in the database
    get('show bookmark') do
      tags 'Bookmarks'
      produces 'application/json'
      response(200, 'successful') do
        run_test! do
          expect(response.body).to include('"title":"Example Bookmark"')
        end
      end

      # Get request on /api/v1/bookmarks/{id} returns the response 404 not found - bookmark with id = {id} when correct id is passed which is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
          run_test! do
            expect(response.body).to include("Couldn't find Bookmark")
          end
      end
    end

    put('update bookmark') do
      tags 'Bookmarks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string }
        }
      }

      # put request on /api/v1/bookmarks/{id} returns 200 response succesful when bookmark id is present in the database and correct valid params are passed
      response(200, 'successful') do
        let(:body_params) do
          {
            title: 'Updated Bookmark Title'
          }
        end
        run_test! do
          expect(response.body).to include('"title":"Updated Bookmark Title"')
        end
      end

      # put request on /api/v1/bookmarks/{id} returns 404 not found when id is not present in the database which bookmark needs to be updated
      response(404, 'not found') do
        let(:id) { 0 }
        let(:body_params) do
          {
            title: 'Updated Bookmark Title'
          }
        end
        run_test! do
          expect(response.body).to include("Couldn't find Bookmark")
        end
      end

      # put request on /api/v1/bookmarks/{id} returns 422 response unprocessable entity when correct parameters for the bookmark to be updated are not passed
      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            title: nil
          }
        end
        schema type: :string
        run_test! do
          expect(response.body).to_not include('"title":null')
        end
      end
    end

    delete('delete bookmark') do
      tags 'Bookmarks'
      produces 'application/json'
      # delete request on /api/v1/bookmarks/{id} returns 204 succesful response when bookmark with id present in the database is succesfully deleted
      response(204, 'successful') do
        run_test! do
          expect(Bookmark.exists?(id)).to eq(false)
        end
      end

      # delete request on /api/v1/bookmarks/{id} returns 404 not found response when bookmark id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Bookmark")
        end
      end
    end
  end

  path '/api/v1/bookmarks/{id}/bookmarkratings' do
    parameter name: 'id', in: :path, type: :integer

    let(:user) { User.create(email: 'test@test.com', password: '123456') }
    let(:bookmark) do
      user
      Bookmark.create(
        url: 'http://example.com',
        title: 'Example Bookmark',
        description: 'An example bookmark',
        topic_id: 1,
        rating: 5,
        user_id: user.id
      )
    end

    let(:id) { bookmark.id }

    post('save bookmark rating score') do
      tags 'Bookmarks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :rating, in: :body, schema: {
        type: :object,
        properties: {
          rating: { type: :integer }
        },
        required: %w[rating]
      }

      response(200, 'successful') do
        let(:rating) { 4 }
        run_test! do
          expect(response.body).to include('"rating":4')
        end
      end
    end

    get('get bookmark rating score') do
      tags 'Bookmarks'
      produces 'application/json'

      response(200, 'successful') do
        let(:bookmark_rating) { BookmarkRating.create(bookmark_id: bookmark.id, user_id: user.id, rating: 5) }
        run_test! do
          expect(response.body).to include('"rating":5')
        end
      end

      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.body).to include("Couldn't find Bookmark")
        end
      end
    end
  end
end
