# spec/requests/api/v1/assignment_controller_spec.rb

require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Assignments API', type: :request do
  before do
    Role.create(id: 1, name: 'Teaching Assistant', parent_id: nil, default_page_id: nil)
    Role.create(id: 2, name: 'Administrator', parent_id: nil, default_page_id: nil)

    Assignment.create(id: 1, name: 'a1')
    Assignment.create(id: 2, name: 'a2')

  end

  let(:institution) { Institution.create(id: 100, name: 'NCSU') }

  let(:user) do
    institution
    User.create(id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: institution.id)
  end


  let(:auth_token) { generate_auth_token(user) }

  path '/api/v1/assignments' do
    get 'Get assignments' do
      tags "Get All Assignments"
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'assignment successfully' do
        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/add_participant/{user_id}' do

    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'user_id', in: :path, type: :string


    post 'Adds a participant to an assignment' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'participant added successfully' do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }
        let(:user_id) { user.id }

        run_test! do
          response_json = JSON.parse(response.body) # Parse the response body as JSON
          expect(response_json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end
      response '404', 'assignment not found' do
        let(:assignment_id) { 3 }
        let(:user_id) { 1 }

        run_test! do
          expect(response).to have_http_status(:not_found)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'participant removed successfully' do
        let(:user_id) { user.id }
        let(:assignment) {create(:assignment)}
        let(:assignment_id) {assignment.id}

        before do
          assignment.add_participant(user.id)
        end

        run_test! do
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment or user not found' do
        let(:assignment_id) { 4 }
        let(:user_id) { 1 }

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end

    end
  end

  path '/api/v1/assignments/{assignment_id}/assign_to_course/{course_id}' do
    parameter name: 'assignment_id', in: :path, type: :string
    parameter name: 'course_id', in: :path, type: :string

    patch 'Make course_id of assignment null' do
      tags 'Assignments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'course_id assigned successfully' do
        let(:course) { create(:course)}
        let(:course_id) { course.id }
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do
          response_json = JSON.parse(response.body) # Parse the response body as JSON
          expect(response_json['course_id']).to eq(course.id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 3 }
        let(:course) { create(:course)}
        let(:course_id) {course.id}

        run_test! do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path '/api/v1/assignments/{assignment_id}/remove_from_course' do
    patch 'Removes assignment from course' do
      tags 'Assignments'
      produces 'application/json'
      parameter name: :assignment_id, in: :path, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }


      response '200', 'assignment removed from course' do
        let(:course) { create(:course) }
        let(:assignment) { create(:assignment, course: course)}
        let(:assignment_id) { assignment.id }
        let(:course_id) { course.id }
        run_test! do
          response_json = JSON.parse(response.body) # Parse the response body as JSON
          expect(response_json['course_id']).to be_nil
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 4 }
        let(:course_id) {1}
        run_test! do
          response_json = JSON.parse(response.body)
          expect(response_json['error']).to eq('Assignment not found')
          expect(response).to have_http_status(:not_found)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response '200', 'assignment copied successfully' do
        let(:assignment) { create(:assignment) } # Assuming you have a Factory for Assignment
        let(:assignment_id) { assignment.id }

        run_test! do
          response_json = JSON.parse(response.body) # Parse the response body as JSON
          expect(response_json['id']).to be_present
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 4 }

        run_test! do
          expect(response).to have_http_status(:not_found)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

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
    end
  end

  path '/api/v1/assignments/{assignment_id}/has_topics' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has topics') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }
        let(:review_type) { 'review' }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
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

  path '/api/v1/assignments/{assignment_id}/has_teams' do
    parameter name: 'assignment_id', in: :path, type: :integer, description: 'Assignment ID'

    get('Check if an assignment has teams') do
      tags 'Assignments'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:assignment) { create(:assignment) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
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
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string
      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      response(200, 'successful') do
        let(:questionnaire) { create(:questionnaire) }
        let(:assignment) { create(:assignment) }
        let(:assignment_id) {assignment.id}
        let(:assignment_questionnaire) { create(:assignment_questionnaire, assignment: assignment, questionnaire: questionnaire, used_in_round: 1) }


        run_test! do |response|
          expect(response).to have_http_status(:ok)
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