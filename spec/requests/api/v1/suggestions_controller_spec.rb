require 'swagger_helper'
require 'rails_helper'

def login_user
  # Create a user using the factory
  user = create(:user)

  # Make a POST request to login
  post '/login', params: { user_name: user.name, password: 'password' }

  # Parse the JSON response and extract the token
  json_response = JSON.parse(response.body)

  # Return the token from the response
  { token: json_response['token'], user: }
end

RSpec.describe 'Suggestions API', type: :request do
  # Login user, grab token, set user and current user
  before(:each) do
    auth_data = login_user
    @token = auth_data[:token]
    @user = auth_data[:user]
    @current_user = @user
  end

  # create default assignment and suggestion
  let(:assignment) { create(:assignment) }
  let(:suggestion) { create(:suggestion, assignment_id: assignment.id, user_id: @user.id) }

  # Testing for add_comment method
  path '/api/v1/suggestions/{id}/add_comment' do
    post 'Add a comment to a suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        },
        required: ['comment']
      }

      # successful comment addition test
      response '201', 'comment_added' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { { comment: 'This is a test comment' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['comment']).to eq('This is a test comment')
          expect(response.status).to eq(201)
        end
      end

      # test for missing or empty comment
      response '422', 'unprocessable entity for missing or empty comment' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }
        let(:comment) { '' }

        before do
          # Mock the params to simulate the request
          allow_any_instance_of(ActionController::Parameters).to receive(:require).with(:id).and_return(id)
          allow_any_instance_of(ActionController::Parameters).to receive(:require).with(:comment).and_return(comment)
          # Mock params[:id] and params[:comment] in the controller context
          allow_any_instance_of(ActionController::Parameters).to receive(:[]).with(:id).and_return(id)
          allow_any_instance_of(ActionController::Parameters).to receive(:[]).with(:comment).and_return(comment)
        end

        run_test! do |response|
          expect(response.status).to eq(422) # Expect 400 if the comment is missing or empty
        end
      end

      # test for suggestion not found
      response '404', 'suggestion not found' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { -1 }
        let(:comment) { { comment: 'Invalid ID' } }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end

  # Tests for approving suggestions
  path '/api/v1/suggestions/{id}/approve' do
    post 'Approve suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'

      # tests for when the user is an instructor/has ta privileges
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end

        # successful suggestion approval
        response '200', 'suggestion approved' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('Approved')
          end
        end

        # test for unprocessable with a record
        response '422', 'unprocessable entity' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          before do
            # Simulating an error in the approval process (e.g., ActiveRecord::RecordInvalid)
            allow_any_instance_of(Suggestion).to receive(:update_attribute).and_raise(ActiveRecord::RecordInvalid.new(suggestion))
          end

          run_test! do |response|
            expect(response.status).to eq(422)
          end
        end

        # test for unprocessable without a record
        response '422', 'unprocessable entity' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          before do
            # Simulating an error in the approval process (e.g., ActiveRecord::RecordInvalid)
            allow_any_instance_of(Suggestion).to receive(:update_attribute).and_raise(ActiveRecord::RecordInvalid)
          end

          run_test! do |response|
            expect(response.status).to eq(422)
          end
        end

        # test for when a suggestion is not found
        response '404', 'suggestion not found' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { -1 }

          run_test! do |response|
            expect(response.status).to eq(404)
          end
        end
      end

      # test cases for when user is a student/doesn't have ta_privileges
      context ' | when user is student | ' do
        # set user as not having ta_privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end

        # test for students not being able to approve suggestions
        response '403', 'students cannot approve suggestions' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(403)
            expect(JSON.parse(response.body)['error']).to eq('Students cannot approve a suggestion.')
          end
        end
      end
    end
  end

  # test cases for creating a suggestion
  path '/api/v1/suggestions' do
    post 'Create suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :suggestion, in: :body, type: :object, required: true,
                description: 'Suggestion object with attributes'

      # test for successful suggestion creation
      response '201', 'suggestion created successfully' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:suggestion) do
          {
            assignment_id: assignment.id,
            auto_signup: true,
            comment: 'This is a great suggestion!',
            description: 'Detailed suggestion description',
            title: 'Suggestion title',
            anonymous: false
          }
        end

        # set up current user to return properly for test
        before do
          allow(controller).to receive(:current_user).and_return(@current_user)
        end

        run_test! do |response|
          expect(response.status).to eq(201)
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Suggestion title')
          expect(data['description']).to eq('Detailed suggestion description')
          expect(data['auto_signup']).to eq(true)
          expect(data['status']).to eq('Initialized')
        end
      end

      # test for a missing parameter
      response '422', 'missing title' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:suggestion) do
          {
            assignment_id: assignment.id,
            auto_signup: true,
            comment: 'This is a great suggestion!',
            description: 'Detailed suggestion description',
            title: '',
            anonymous: false
          }
        end

        # set up current user to return current user properly
        before do
          allow(controller).to receive(:current_user).and_return(@current_user)
        end

        run_test! do |response|
          expect(response.status).to eq(422)
          data = JSON.parse(response.body)
          expect(data['error']).to eq('title is missing')
        end
      end

      # test for invalid suggestion given
      response '422', 'unprocessable entity' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:suggestion) do
          {
            assignment_id: assignment.id,
            auto_signup: true,
            comment: 'This is a great suggestion!',
            description: 'Detailed suggestion description',
            title: 'Sample Suggestion',
            anonymous: false
          }
        end

        before do
          allow(controller).to receive(:current_user).and_return(@current_user)
          suggestion = build(:suggestion, assignment_id: assignment.id, user_id: @user.id)
          allow(Suggestion).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(suggestion))
        end

        run_test! do |response|
          expect(response.status).to eq(422)
        end
      end
    end
  end

  # test cases for deleting suggestions
  path '/api/v1/suggestions/{id}' do
    delete 'Delete suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'

      # test cases for when the user is an instructor
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end

        # test for successful suggestion deletion
        response '204', 'suggestion deleted' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(204)
            expect(response.body).to be_empty
          end
        end

        # test for record not being destroyed
        response '422', 'unprocessable entity' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          before do
            # Simulating an error in the deletion process
            allow_any_instance_of(Suggestion).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
          end

          run_test! do |response|
            expect(response.status).to eq(422)
          end
        end

        # test for when suggestion is not found/doesn't exist
        response '404', 'suggestion not found' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { -1 }

          run_test! do |response|
            expect(response.status).to eq(404)
          end
        end
      end

      # test cases for when the user is a student
      context ' | when user is student | ' do
        # set user to not have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end

        # test to make sure students cannot delete suggestions
        response '403', 'students cannot delete suggestions' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(403)
            expect(JSON.parse(response.body)['error']).to eq('Students cannot delete suggestions.')
          end
        end
      end
    end
  end

  # test cases for indexing/listing all suggestions
  path '/api/v1/suggestions' do
    get 'list all suggestions' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :query, type: :integer, required: true, description: 'ID of the assignment'

      # test cases for when the user is an instructor/has ta privileges
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
          suggestion.update(assignment_id: assignment.id)
        end

        # test for successful indexing
        response '200', 'suggestions listed' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { assignment.id }

          run_test! do |response|
            expect(response.status).to eq(200)
            expect(JSON.parse(response.body).size).to eq(1)
          end
        end
      end

      # test case for when user is a student
      context ' | when user is student | ' do
        # set user to not have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end

        # test for student to be forbidden from indexing suggestions
        response '403', 'students cannot index suggestions' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { assignment.id }

          run_test! do |response|
            expect(response.status).to eq(403)
            expect(JSON.parse(response.body)['error']).to eq('Students cannot view all suggestions of an assignment.')
          end
        end
      end
    end
  end

  # test cases for rejecting suggestions
  path '/api/v1/suggestions/{id}/reject' do
    post 'Reject suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'

      # test cases for when user is instructor/ta privileges
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end

        # test for successful suggestion rejection
        response '200', 'suggestion rejected' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['status']).to eq('Rejected')
          end
        end

        # test for suggestion already being approved
        response '422', 'suggestion already approved' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          before do
            # Simulate suggestion status as 'Approved'
            suggestion.update!(status: 'Approved')
          end

          run_test! do |response|
            expect(response.status).to eq(422)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['error']).to eq('Suggestion has already been approved.')
          end
        end

        # test for when the suggestion not being found
        response '404', 'suggestion not found' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { -1 }

          run_test! do |response|
            expect(response.status).to eq(404)
          end
        end
      end

      # test cases for when user is a student/doesn't have ta privileges
      context ' | when user is student | ' do
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
        end
        response '403', 'students cannot reject suggestions' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(403)
            expect(JSON.parse(response.body)['error']).to eq('Students cannot reject a suggestion.')
          end
        end
      end
    end
  end

  # test cases for showing suggestions
  path '/api/v1/suggestions/{id}' do
    get 'show suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'

      # tests for when user is a instructor/has ta privileges
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end
        response '200', 'suggestion details and comments returned' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['suggestion']['id']).to eq(suggestion.id)
            expect(data['comments']).to be_an(Array)
            expect(response.status).to eq(200)
          end
        end
      end

      # test cases for when user is a student/doesn't have ta privilges
      context ' | when user is student | ' do
        # set user to not have ta privileges and make sure current user is set properly
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
          allow(controller).to receive(:current_user).and_return(@current_user)
        end

        # test cases for when user is owner of suggestion
        context ' | when user is student owner to suggestion | ' do
          # make sure user is set as owner of suggestion
          before(:each) do
            # Simulate the student owning the suggestion
            suggestion.update!(user_id: @user.id)
          end
          # test for student being able to view their own suggestion
          response '200', 'student can view their own suggestion' do
            let(:Authorization) { "Bearer #{@token}" }
            let(:id) { suggestion.id }

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data['suggestion']['id']).to eq(suggestion.id)
              expect(data['comments']).to be_an(Array)
              expect(response.status).to eq(200)
            end
          end
        end

        # test case for when user is not owner of suggestion
        context ' | when user is not student owner to suggestion | ' do
          before(:each) do
            # Simulate the student not owning the suggestion
            suggestion_double = double('Suggestion', id: suggestion.id, user_id: 9999)
            allow(Suggestion).to receive(:find).with(suggestion.id.to_s).and_return(suggestion_double)
          end

          # make sure student can't view suggestions they don't own/are a part of
          response '403', 'student can\'t view other suggestions' do
            let(:Authorization) { "Bearer #{@token}" }
            let(:id) { suggestion.id }

            run_test! do |response|
              expect(response.status).to eq(403)
            end
          end
        end
      end

      # test for when suggestion doesn't exist
      response '404', 'suggestion not found' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { -1 }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end
    end
  end

  # test cases for updating a suggestion
  path '/api/v1/suggestions/{id}' do
    patch 'update suggestion' do
      tags 'Suggestions'
      consumes 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true, description: 'ID of the suggestion'

      # test cases for when user is an instructor/has ta privileges
      context '| when user is instructor | ' do
        # set user to have ta privileges
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(true)
        end

        # test for successful suggestion update
        response '200', 'suggestion updated' do
          let(:Authorization) { "Bearer #{@token}" }
          let(:id) { suggestion.id }

          run_test! do |response|
            expect(response.status).to eq(200)
          end
        end
      end

      # test cases for when user is a student
      context ' | when user is student | ' do
        # set user to be a student and setup current user
        before(:each) do
          allow(AuthorizationHelper).to receive(:current_user_has_ta_privileges?).and_return(false)
          allow(controller).to receive(:current_user).and_return(@current_user)
        end

        # test cases for when student is owner/a part of suggestion
        context ' | when user is student owner to suggestion | ' do
          before(:each) do
            # Simulate the student owning the suggestion
            suggestion.update!(user_id: @user.id)
          end

          # test to make sure students can update their own suggestion(s)
          response '200', 'student can update their own suggestion' do
            let(:Authorization) { "Bearer #{@token}" }
            let(:id) { suggestion.id }

            run_test! do |response|
              expect(response.status).to eq(200)
            end
          end
        end

        # test cases for when student is not owner to suggestion
        context ' | when user is not student owner to suggestion | ' do
          before(:each) do
            # Simulate the student not owning the suggestion
            suggestion_double = double('Suggestion', id: suggestion.id, user_id: 9999)
            allow(Suggestion).to receive(:find).with(suggestion.id.to_s).and_return(suggestion_double)
          end

          # test for forbidding student(s) from updating suggestions other then their own
          response '403', 'student can\'t updates other suggestions' do
            let(:Authorization) { "Bearer #{@token}" }
            let(:id) { suggestion.id }

            run_test! do |response|
              expect(response.status).to eq(403)
            end
          end
        end
      end

      # test for suggestion not being found
      response '404', 'suggestion not found' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { -1 }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end

      # test for suggestion being invalid in some form/missing
      response '422', 'unprocessable entity' do
        let(:Authorization) { "Bearer #{@token}" }
        let(:id) { suggestion.id }

        before do
          allow(Suggestion).to receive(:find).and_return(suggestion) # Mock finding the suggestion
          allow(suggestion).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(suggestion))
        end

        run_test! do |response|
          expect(response.status).to eq(422)
        end
      end
    end
  end
end
