require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/teams_participants', type: :request do
  before(:all) do
    # Create an institution
    @institution = Institution.create!(name: "NC State2")

    # Create roles explicitly using find_or_create_by! so duplicates are not created.
    @instructor_role = Role.find_or_create_by!(id: 3, name: "Instructor2")
    @ta_role         = Role.find_or_create_by!(id: 2, name: "Teaching Assistant2", parent_id: @instructor_role.id)
    @student_role    = Role.find_or_create_by!(id: 1, name: "Student2", parent_id: @ta_role.id)
  end

  # Create an instructor similar to your example.
  let(:instructor) do
    User.create!(
      id: 1,
      name: "profa",
      password_digest: "password",
      role_id: @instructor_role.id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      institution_id: @institution.id
    )
  end

  # Create additional users using factories for student and TA.
  let(:student)    { create(:user, role: @student_role) }
  let(:ta)         { create(:user, role: @ta_role) }

  # Create an assignment and a team belonging to that assignment.
  let(:assignment) { create(:assignment, instructor_id: instructor.id) }
  # Assuming your Team model uses parent_id to store the assignment id.
  let(:team)       { create(:team, parent_id: assignment.id) }

  # Create a participant and associate with the team.
  let(:participant){ create(:user, name: 'Test Participant') }
  let!(:teams_user){ create(:teams_user, user: participant, team: team) }

  # Authorization header using JWT.
  let(:token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # Swagger-style tests

  path '/api/v1/teams_participants/update_duties' do
    put('update participant duties') do
      tags 'Teams Participants'
      consumes 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          teams_user_id: { type: :integer },
          teams_user: {
            type: :object,
            properties: {
              duty_id: { type: :integer }
            },
            required: ['duty_id']
          },
          participant_id: { type: :integer }
        },
        required: ['teams_user_id', 'teams_user', 'participant_id']
      }
      response(302, 'redirect to student teams view') do
        let(:payload) do
          {
            teams_user_id: teams_user.id,
            teams_user: { duty_id: 2 },
            participant_id: participant.id
          }
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "Duty updated successfully" }
            }
          }
        end
        run_test! do |response|
          expect(response.headers['Location']).to include('student_teams')
        end
      end
    end
  end

  path '/api/v1/teams_participants/list_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'
    get('list participants') do
      tags 'Teams Participants'
      produces 'application/json'
      response(200, 'successful') do
        let(:id) { team.id }
        run_test! do |response|
          json = JSON.parse(response.body) rescue []
          expect(json).to be_an(Array)
        end
      end
      response(404, 'team not found') do
        let(:id) { 0 }
        run_test! do |response|
          expect(response.body).to include("Couldn't find Team")
        end
      end
    end
  end

  path '/api/v1/teams_participants/add_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'
    post('add participant') do
      tags 'Teams Participants'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: { name: { type: :string } },
            required: ['name']
          }
        },
        required: ['user']
      }
      response(302, 'redirect to teams list') do
        let(:payload) { { user: { name: participant.name } } }
        let(:id) { team.id }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "The participant \"#{participant.name}\" has been successfully added to \"Team\"." }
            }
          }
        end
        run_test! do |response|
          expect(response.headers['Location']).to include('teams')
        end
      end
      response(302, 'error and redirect to root') do
        let(:payload) { { user: { name: 'Invalid User' } } }
        let(:id) { team.id }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => { example: { error: "Participant not found" } }
          }
        end
        run_test! do |response|
          expect(response.headers['Location']).to include(root_path)
        end
      end
    end
  end

  path '/api/v1/teams_participants/delete_participant/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'TeamsUser ID'
    delete('delete participant') do
      tags 'Teams Participants'
      produces 'application/json'
      response(302, 'redirect to teams list') do
        let(:id) { teams_user.id }
        run_test! do |response|
          expect(TeamsUser.exists?(teams_user.id)).to be_falsey
          expect(response.headers['Location']).to include('teams')
        end
      end
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do |response|
          expect(response.body).to include("Couldn't find TeamsUser")
        end
      end
    end
  end

  path '/api/v1/teams_participants/delete_selected_participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Team ID'
    delete('delete selected participants') do
      tags 'Teams Participants'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          item: { type: :array, items: { type: :integer } }
        },
        required: ['item']
      }
      response(302, 'redirect to list participants') do
        let(:id) { team.id }
        let(:new_user1) { create(:user) }
        let(:new_user2) { create(:user) }
        let!(:teams_user1) { create(:teams_user, team: team, user: new_user1) }
        let!(:teams_user2) { create(:teams_user, team: team, user: new_user2) }
        let(:payload) { { item: [teams_user1.id, teams_user2.id] } }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => { example: { message: "Selected participants deleted" } }
          }
        end
        run_test! do |response|
          expect(TeamsUser.exists?(teams_user1.id)).to be_falsey
          expect(TeamsUser.exists?(teams_user2.id)).to be_falsey
          expect(response.headers['Location']).to include('list_participants')
        end
      end
      response(404, 'team not found') do
        let(:id) { 0 }
        let(:payload) { { item: [] } }
        run_test! do |response|
          expect(response.body).to include("Couldn't find Team")
        end
      end
    end
  end
end
