require 'swagger_helper'

# Given the fact that our knowledge of the other models are very limited, we used an extensive amount of ChatGPT to
# help generate a lot of the information in this file. Granted, a lot of this was tweaked by hand to fix the issues
# but ChatGPT did generate a lot of the backbone of information used in these test cases
RSpec.describe 'Grades API', type: :request do
  before do

    # Create roles
    @instructor_role = Role.find_or_create_by(name: 'Instructor')
    @student_role = Role.find_or_create_by(name: 'Student')

    # Create institution
    @institution = Institution.find_or_create_by(name: 'Test Institution')

    # Create instructor and course
    @instructor = create(:instructor, institution: @institution, role: @instructor_role)
    @course = create(:course, instructor: @instructor, institution: @institution)

    # Create assignment
    @assignment = create(:assignment, instructor: @instructor, course: @course)

    # Create questionnaire without validating assignment presence
    allow_any_instance_of(Questionnaire).to receive(:assignment).and_return(@assignment)
    @questionnaire = build(:questionnaire, instructor: @instructor)
    @questionnaire.save(validate: false)

    # Create question linked to questionnaire
    @question = create(:question, questionnaire: @questionnaire)

    # Create student user
    @student_user = create(:user, role: @student_role, institution: @institution)

    # Create assignment participant
    @participant = create(:assignment_participant, assignment: @assignment, user: @student_user)

    # Create team and add student to the team
    @team = create(:team, assignment: @assignment)
    TeamsUser.create(team: @team, user: @student_user)

    # Link questionnaire to assignment
    create(:assignment_questionnaire, assignment: @assignment, questionnaire: @questionnaire)

    # Create participant score with all required associations
    @participant_score = create(
      :participant_score,
      assignment_participant: @participant,
      assignment: @assignment,
      question: @question,
      score: 90,
      total_score: 100,
      round: 1
    )
  end

  before(:each) do
    post '/login', params: { user_name: @instructor.name, password: 'password' }
    @token = JSON.parse(response.body)['token']
    #allow_any_instance_of(GradesController).to receive(:session).and_return({ user: @instructor })
  end

  path '/api/v1/grades/{action}/action_allowed' do
    parameter name: 'action', in: :path, type: :string, description: 'the action the user wishes to perform'
    parameter name: 'id', in: :query, type: :integer, description: 'Assignment ID', required: true

    let(:action) { 'view' }
    let(:id) { @assignment.id }

    get('action_allowed') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }
      response(200, 'successful') do
        run_test!
      end
    end
  end

  path '/api/v1/grades/{id}/view' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID', required: true

    let(:id) { @assignment.id }

    get('view') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }
      response(200, 'successful') do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']['id']).to eq(@assignment.id)
          expect(data['scores']).to be_present
          expect(data['averages']).to be_present
          expect(data['avg_of_avg']).to be_present
          expect(data['review_score_count']).to be_present
        end
      end
    end
  end

  path '/api/v1/grades/{id}/view_team' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment ID', required: true

    let(:id) { @assignment.id }

    get('view_team') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }
      response(200, 'successful') do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']['id']).to eq(@assignment.id)
          expect(data['scores']).to be_present
          expect(data['averages']).to be_present
          expect(data['avg_of_avg']).to be_present
          expect(data['review_score_count']).to be_present
        end
      end
    end
  end

  path '/api/v1/grades/{id}/edit' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment Participant ID', required: true

    let(:id) { @participant.id }

    get('edit') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }
      response(200, 'successful') do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['participant']['id']).to eq(@participant.id)
          expect(data['assignment']['id']).to eq(@assignment.id)
          expect(data['questions']).to be_present
          expect(data['scores']).to be_present
        end
      end

      response(404, 'not found') do
        let(:id) { 9999 }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq("Assignment participant 9999 not found")
        end
      end
    end
  end

  path '/api/v1/grades/{id}/instructor_review' do
    parameter name: 'id', in: :path, type: :integer, description: 'Assignment Participant ID', required: true

    let(:id) { @participant.id }

    get('instructor_review') do
      tags 'Grades'
      let(:'Authorization') { "Bearer #{@token}" }

      response(200, 'successful when creating a new review mapping') do
        # Here we let the actual method be called to set up the new mapping
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['controller']).to eq('response')
          expect(data['action']).to eq('new')
          expect(data['id']).to be_present
          expect(data['return']).to eq('instructor')
        end
      end

      response(200, 'successful when editing an existing review') do
        # Create a review mapping and response to test editing
        let!(:review_mapping) { create(:review_mapping, assignment_participant: @participant) }
        let!(:response_record) { create(:response, map_id: review_mapping.id) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['controller']).to eq('response')
          expect(data['action']).to eq('edit')
          expect(data['id']).to eq(response_record.id)
          expect(data['return']).to eq('instructor')
        end
      end

      response(404, 'not found') do
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq("Assignment participant 9999 not found")
        end
      end
    end
  end
end
