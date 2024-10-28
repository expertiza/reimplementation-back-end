require 'swagger_helper'

RSpec.describe 'Grades API', type: :request do
  before do

    # Create roles
    @student_role = Role.find_or_create_by(name: 'student', id: Role::STUDENT)
    @instructor_role = Role.find_or_create_by(name: 'instructor', id: Role::INSTRUCTOR)

    # Create an instructor user
    @institution = Institution.find_or_create_by(name: 'Test Institution')
    @instructor = create(:user, :instructor, role: @instructor_role, institution: @institution)

    # Create a course and assignment associated with the instructor
    # In your test setup
    @course = create(:course, instructor: @instructor, institution: @institution)

    @assignment = create(:assignment, instructor: @instructor, course: @course)

    # Create a student user and participant
    @student_user = create(:user, :student, role: @student_role, institution: @institution)
    @participant = create(:assignment_participant, assignment: @assignment, user: @student_user)

    # Create a team and add the participant
    @team = create(:team, assignment: @assignment)
    TeamsUser.create(team: @team, user: @student_user)

    # Create a questionnaire and question
    @questionnaire = create(:questionnaire, instructor: @instructor)
    @question = create(:question, questionnaire: @questionnaire)

    # Associate questionnaire with assignment
    create(:assignment_questionnaire, assignment: @assignment, questionnaire: @questionnaire)

    # Create participant scores
    create(
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
    post '/login', params: { user_name: @user.name, password: 'password' }
    @token = JSON.parse(response.body)['token']
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
end