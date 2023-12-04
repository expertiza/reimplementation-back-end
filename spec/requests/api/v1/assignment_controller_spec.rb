# spec/requests/api/v1/assignment_controller_spec.rb

require 'swagger_helper'

RSpec.describe 'Assignments API', type: :request do
  path '/api/v1/assignments/{assignment_id}/add_participant/{user_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'user_id', in: :path, type: :string

    post 'Adds a participant to an assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'

      response '200', 'participant added successfully' do
        let(:assignment) { create(:assignment) } # Assuming you have a Factory for Assignment
        let(:assignment_id) { assignment.id }
        let(:user) { create(:user) } # Assuming you have a Factory for User
        let(:user_id) { user.id }

        run_test! do
          expect(json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 'nonexistent_id' }
        let(:user_id) { 'some_user_id' }

        run_test! do
          expect(json['error']).to eq('Assignment not found')
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', 'unprocessable entity' do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }
        let(:user_id) { 'invalid_user_id' }

        run_test! do
          expect(json).to include('errors')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/remove_participant/{user_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'user_id', in: :path, type: :string

    delete 'Removes a participant from an assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'

      response '200', 'participant removed successfully' do
        let(:assignment) { create(:assignment) }
        let(:user) { create(:user) }
        let(:assignment_id) { assignment.id }
        let(:user_id) { user.id }

        before do
          assignment.add_participant(user.id)
        end

        run_test! do
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment or user not found' do
        let(:assignment_id) { 'nonexistent_id' }
        let(:user_id) { 'nonexistent_user_id' }

        run_test! do
          expect(json['error']).to eq('Assignment not found') # or 'User not found'
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', 'unprocessable entity' do
        let(:assignment) { create(:assignment) }
        let(:user) { create(:user) }
        let(:assignment_id) { assignment.id }
        let(:user_id) { 'invalid_user_id' }

        run_test! do
          expect(json).to include('errors')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/assign_courses_to_assignment/{course_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'course_id', in: :path, type: :string

    patch 'Make course_id of assignment null' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'

      response '200', 'course_id removed successfully' do
        let(:assignment) { create(:assignment, course_id: 'some_course_id') } # Assuming you have a Factory for Assignment
        let(:assignment_id) { assignment.id }
        let(:course_id) { 'null' } # or any value that represents setting course_id to null

        run_test! do
          expect(json['course_id']).to be_nil
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 'nonexistent_id' }
        let(:course_id) { 'some_course_id' }

        run_test! do
          expect(json['error']).to eq('Assignment not found')
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', 'unprocessable entity' do
        let(:assignment) { create(:assignment, course_id: 'some_course_id') }
        let(:assignment_id) { assignment.id }
        let(:course_id) { 'invalid_course_id' }

        run_test! do
          expect(json).to include('errors')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/remove_assignment_from_course' do
    patch 'Removes assignment from course' do
      tags 'Assignments'
      produces 'application/json'
      parameter name: :assignment_id, in: :path, type: :integer, required: true

      response '200', 'assignment removed from course' do
        let(:assignment) { create(:assignment) } # Assuming you have a FactoryBot factory for assignments

        run_test! do
          # Add assertions as needed
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 'nonexistent_id' }

        run_test! do
          # Add assertions as needed
        end
      end

      response '422', 'unprocessable entity' do
        let(:assignment) { create(:assignment) } # Assuming you have a FactoryBot factory for assignments
        let(:assignment_id) { assignment.id }

        before do
          allow_any_instance_of(Assignment).to receive(:remove_assignment_from_course).and_return(false)
        end

        run_test! do
          # Add assertions as needed
        end
      end
    end
  end


  path '/api/v1/assignments/{assignment_id}/copy_assignment' do
    parameter name: 'assignment_id', in: :path, type: :string

    post 'Copy an existing assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'

      response '200', 'assignment copied successfully' do
        let(:assignment) { create(:assignment) } # Assuming you have a Factory for Assignment
        let(:assignment_id) { assignment.id }

        run_test! do
          expect(json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 'nonexistent_id' }

        run_test! do
          expect(json['error']).to eq('Assignment not found')
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', 'unprocessable entity' do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        before do
          allow_any_instance_of(Assignment).to receive(:copy_assignment).and_return(double(save: false, errors: { message: 'Some error' }))
        end

        run_test! do
          expect(json).to include('errors')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/api/v1/assignments/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID'

    delete('Delete an assignment') do
      tags 'Assignments'
      produces 'application/json'
      consumes 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Assignment deleted successfully!')
        end
      end

      response(404, 'Assignment not found') do
        let(:id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end

      response(422, 'Unprocessable Entity') do
        let(:assignment) { create(:assignment) }
        let(:id) { assignment.id }

        before do
          allow_any_instance_of(Assignment).to receive(:destroy).and_return(false)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Failed to delete assignment')
          expect(data['details']).to be_present
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/has_badge' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has a badge') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/pair_programming_enabled' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if pair programming is enabled for an assignment') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/has_topics' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has topics') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/team_assignment' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment is a team assignment') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/valid_num_review/{review_type}' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'
    parameter name: 'review_type', in: :path, type: :string, description: 'Review Type'

    get('Check if an assignment has a valid number of reviews for a specific type') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }
        let(:review_type) { 'some_type' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID
        let(:review_type) { 'some_type' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/is_calibrated' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment is calibrated') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/has_teams' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has teams') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/staggered_and_no_topic' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment is staggered and has no topic') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/create_node' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    post('Create a node for an assignment') do
      tags 'Assignments'
      consumes 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/varying_rubrics_by_round' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has varying rubrics by round') do
      tags 'Assignments'
      produces 'application/json'
      security [ { api_key: [] } ]

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_truthy
        end
      end

      response(404, 'Assignment not found') do
        let(:assignment_id) { 999 } # Non-existent ID

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Assignment not found')
        end
      end
    end
  end
end
