require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Grades API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) do
    User.create!(
      name: "instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:ta) do
    User.create!(
      name: "ta",
      password_digest: "password",
      role_id: @roles[:ta].id,
      full_name: "Teaching Assistant",
      email: "ta@example.com"
    )
  end

  let(:student) do
    User.create!(
      name: "student",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Name",
      email: "student@example.com"
    )
  end

  let(:student2) do
    User.create!(
      name: "student2",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Two",
      email: "student2@example.com"
    )
  end

  let(:course) {create(:course)}

  let!(:assignment) { Assignment.create!(name: 'Test Assignment', instructor_id: instructor.id, course_id: course.id) }
  let!(:team) { AssignmentTeam.create!(name: 'Team 1', parent_id: assignment.id) }
  let!(:participant) { AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, team_id: team.id, handle: student.name) }
  let!(:participant2) { AssignmentParticipant.create!(user_id: student2.id, parent_id: assignment.id, team_id: team.id, handle: student2.name) }
  

  let(:instructor_token) { JsonWebToken.encode({id: instructor.id}) }
  let(:ta_token) { JsonWebToken.encode({id: ta.id}) }
  let(:student_token) { JsonWebToken.encode({id: student.id}) }

  let(:Authorization) { "Bearer #{instructor_token}" }

  path '/grades/{assignment_id}/view_all_scores' do
    get 'Retrieve all review scores for an assignment' do
      tags 'Grades'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :assignment_id, in: :path, type: :integer, description: 'ID of the assignment'
      parameter name: :participant_id, in: :query, type: :integer, required: false, description: 'ID of the participant'
      parameter name: :team_id, in: :query, type: :integer, required: false, description: 'ID of the team'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns all scores for assignment' do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('team_scores')
          expect(data).to have_key('participant_scores')
        end
      end

      response '200', 'Returns participant scores when participant_id provided' do
        let(:assignment_id) { assignment.id }
        let(:participant_id) { participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['participant_scores']).to be_present
        end
      end

      response '200', 'Returns team scores when team_id provided' do
        let(:assignment_id) { assignment.id }
        let(:team_id) { team.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['team_scores']).to be_present
        end
      end

      response '403', 'Forbidden - Student cannot access' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to view_all_scores this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/grades/{assignment_id}/view_our_scores' do
    get 'Retrieve team scores for the requesting student' do
      tags 'Grades'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :assignment_id, in: :path, type: :integer, description: 'ID of the assignment'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns team scores' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('reviews_of_our_work')
          expect(data).to have_key('avg_score_of_our_work')
        end
      end

      response '403', 'Assignment Participant not found' do
        let(:assignment_id) { 999 }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to view_our_scores this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/grades/{assignment_id}/view_my_scores' do
    get 'Retrieve individual participant scores' do
      tags 'Grades'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :assignment_id, in: :path, type: :integer, description: 'ID of the assignment'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns participant scores' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('reviews_of_me')
          expect(data).to have_key('reviews_by_me')
          expect(data).to have_key('author_feedback_scores')
          expect(data).to have_key('avg_score_from_my_teammates')
          expect(data).to have_key('avg_score_to_my_teammates')
          expect(data).to have_key('avg_score_from_my_authors')
        end
      end

      response '403', 'Participant not found' do
        let(:assignment_id) { 999 }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to view_my_scores this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:assignment_id) { assignment.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/grades/{participant_id}/edit' do
    get 'Get grade assignment interface data' do
      tags 'Grades'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :participant_id, in: :path, type: :integer, description: 'ID of the participant'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns participant, assignment, items, and scores' do
        let(:participant_id) { participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('participant')
          expect(data).to have_key('assignment')
          expect(data).to have_key('items')
          expect(data).to have_key('scores')
          expect(data['scores']).to have_key('my_team')
          expect(data['scores']).to have_key('my_own')
        end
      end

      response '404', 'Participant not found' do
        let(:participant_id) { 999 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Found')
        end
      end

      response '403', 'Forbidden - Student cannot access' do
        let(:participant_id) { participant.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to edit this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:participant_id) { participant.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/grades/{participant_id}/assign_grade' do
    patch 'Assign grades and comment to team' do
      tags 'Grades'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :participant_id, in: :path, type: :integer, description: 'ID of the participant'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'
      parameter name: :grade_data, in: :body, schema: {
        type: :object,
        properties: {
          grade_for_submission: { type: :number, description: 'Grade for the submission' },
          comment_for_submission: { type: :string, description: 'Comment for the submission' }
        }
      }

      response '200', 'Team grade and comment assigned successfully' do
        let(:participant_id) { participant.id }
        let(:grade_data) { { grade_for_submission: 95, comment_for_submission: 'Excellent work!' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq("Grade and comment assigned to team #{team.name} successfully.")
          
          team.reload
          expect(team.grade_for_submission).to eq(95)
          expect(team.comment_for_submission).to eq('Excellent work!')
        end
      end

      response '422', 'Failed to assign team grade or comment' do
        let(:participant_id) { participant.id }
        let(:grade_data) { { grade_for_submission: nil } }

        before do
          allow_any_instance_of(AssignmentTeam).to receive(:save).and_return(false)
        end

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq("Failed to assign grade or comment to team #{team.name}." )
        end
      end

      response '404', 'Participant not found' do
        let(:participant_id) { 999 }
        let(:grade_data) { { grade_for_submission: 95 } }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Found')
        end
      end

      response '403', 'Forbidden - Student cannot access' do
        let(:participant_id) { participant.id }
        let(:grade_data) { { grade_for_submission: 95 } }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to assign_grade this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:participant_id) { participant.id }
        let(:grade_data) { { grade_for_submission: 95 } }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  path '/grades/{participant_id}/instructor_review' do
    get 'Begin or continue grading a submission' do
      tags 'Grades'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :participant_id, in: :path, type: :integer, description: 'ID of the participant'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns mapping and redirect information for new review' do
        let(:participant_id) { participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('map_id')
          expect(data).to have_key('response_id')
          expect(data).to have_key('redirect_to')
          expect(data['redirect_to']).to include('/response/new/') if data['response_id'].nil?
        end
      end

      response '200', 'Returns mapping and redirect information for existing review' do
        let(:participant_id) { participant.id }
        
        before do
          reviewer = AssignmentParticipant.create!(user_id: instructor.id, parent_id: assignment.id, handle: instructor.name)
          mapping = ReviewResponseMap.create!(
            reviewed_object_id: assignment.id,
            reviewer_id: reviewer.id,
            reviewee_id: team.id
          )
          Response.create!(map_id: mapping.id)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['response_id']).to be_present
          expect(data['redirect_to']).to include('/response/edit/')
        end
      end

      response '404', 'Participant not found' do
        let(:participant_id) { 999 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Found')
        end
      end

      response '403', 'Forbidden - Student cannot access' do
        let(:participant_id) { participant.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to instructor_review this grades')
        end
      end

      response '401', 'Unauthorized' do
        let(:participant_id) { participant.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end

  # Testing with Teaching Assistant permissions
  describe 'Teaching Assistant access' do
    before do
      TaMapping.create!(course_id: course.id, user_id: ta.id)
    end

    it 'creates the TA mapping' do
      expect(TaMapping.exists?(course_id: course.id, user_id: ta.id)).to be true
    end

    it 'allows TA to access view_all_scores' do
      get "/grades/#{assignment.id}/view_all_scores", headers: { 'Authorization' => "Bearer #{ta_token}" }
      expect(response).to have_http_status(:ok)
    end

    it 'denies TA from accessing instructor_review' do
      get "/grades/#{participant.id}/instructor_review", headers: { 'Authorization' => "Bearer #{ta_token}" }
      expect(response).to have_http_status(:forbidden)
    end

    it 'denies TA from assigning grades' do
      patch "/grades/#{participant.id}/assign_grade", 
            params: { grade_for_submission: 90 },
            headers: { 'Authorization' => "Bearer #{ta_token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end
end