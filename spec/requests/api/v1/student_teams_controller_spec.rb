require 'swagger_helper'

RSpec.describe 'Student Teams API', type: :request do
  path '/api/v1/student_teams' do
    # List all Student Teams
    get('List all Student Teams') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post 'Create a Student Team' do
      tags 'Student Teams'
      consumes 'application/json'
      
      let(:institution) do
        Institution.create!(
          name: 'North Carolina State University'
        )
      end

      let!(:instructor_role) { Role.find_or_create_by(name: 'Instructor') }
      let!(:student_role) { Role.find_or_create_by(name: 'Student') }
    
    
      let(:instructor_user) do
        User.create!(
          name: 'Dr. Ed Gehringer1',
          email: 'gehringer@example.com',
          password: 'password123',
          full_name: 'admin admin',
          institution_id: institution.id,
          role_id: instructor_role.id,
          handle: 'instructor'
        )
      end
    
      let(:course) do
        Course.create!(
          name: '2476. Refactor',
          directory_path: '/',
          info: 'OODD',
          private: false,
          instructor_id: instructor_user.id,
          institution_id: institution.id
        )
      end
    
      let(:assignment) do
        Assignment.create!(
          title: 'Project 4 BRO',
          description: '2476. Reimplementing',
          course_id: course.id,
          instructor_id: instructor_user.id
        )
      end
    
      let!(:students) do
        created_students = []
        3.times do |i|
          student = User.create!(
            name: "Student #{i + 1}",
            email: "Student#{i + 1}@gmail.com",
            password: 'password123',
            full_name: "Student #{i + 1}",
            institution_id: institution.id,
            role_id: student_role.id,
            handle: "Student #{i + 1}"
          )
    
          AssignmentParticipant.create!(
            assignment: assignment,
            user: student,
            handle: "Student #{i + 1}"
          )
    
          created_students << student
        end
        created_students
      end
    
      parameter name: :student_team_request, in: :body, schema: {
        type: :object,
        properties: {
          team: {
            type: :object,
            properties: {
              name: {type: :string}
            }
          },
          student_id: { type: :integer}
        }
      }
      security [Bearer: {}]
      
      # Scenario 1: Successfully create a team
      response(201, 'created') do
        let(:student_team_request) do
          { team: {name: "HelloThere"}, student_id: students.first.id}
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response.status).to eq(201)
        end
      end

      # Scenario 2: Team name is already in use (conflict)
      response(422, 'unprocessable entity') do
        let(:existing_team) { create(:team, name: 'ABCD10', assignment_id: assignment.id) }

        let(:team) do
          post '/api/v1/student_teams', params: { team: { name: 'ABCD10' }, student_id: students.first.id }, as: :json
        end

        run_test! do
          expect(response.status).to eq(422)
          expect(response.body).to include('"error":"That team name is already in use."')
        end
      end

      # Scenario 3: Invalid team creation (empty name)
      response(422, 'unprocessable entity') do
        let(:student_team_request) do
          { team: {name: ""}, student_id: students.first.id}
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(response.status).to eq(422)
          expect(response.body).to include('error')
        end
      end

      response(404, 'not_found') do
        let(:team) do
          post '/api/v1/student_teams', params: { team: { name: 'ABCD10' }, student_id: 0 }, as: :json
        end
          run_test! do
            expect(response.status).to eq(404)
            expect(response.body).to include('not found')
          end
      end

    end

    patch('Update a Student Team') do
      tags 'Student Teams'
      consumes 'application/json'
      produces 'application/json'
      security [Bearer: {}]
      parameter name: :student_team_request, in: :body, schema: {
        type: :object,
        properties: {
          team: {
            type: :object,
            properties: {
              name: {type: :string}
            }
          },
          team_id: { type: :integer}
        }
      }

      # Scenario 1: Team name updated successfully
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.status).to eq(200)
        end
      end

      # Scenario 2: Invalid team updation (empty name)
      response(422, 'unprocessable entity') do
        let(:student_team_request) do
          { team: {name: ""}, team_id: 2}
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.status).to eq(422)
          expect(response.body).to include('Team name should not be empty')
        end
      end
      # Scenario 3: Team Name already present
      response(422, 'unprocessable entity') do
        let(:existing_team) { create(:team, name: 'ABCD10', team_id: 3) }

        let(:team) do
          post '/api/v1/student_teams', params: { team: { name: 'ABCD10' }, team_id: 2 }, as: :json
        end

        run_test! do
          expect(response.status).to eq(422)
          expect(response.body).to include('"error":"That team name is already in use."')
        end
      end
      #Scenario 4 : Invalid Team ID
      response(404, 'not_found') do
        let(:team) do
          post '/api/v1/student_teams', params: { team: { name: 'ABCD10' }, team_id: 0 }, as: :json
        end
          run_test! do
            expect(response.status).to eq(404)
            expect(response.body).to include('not found')
          end
      end

    end
  end
  path '/api/v1/student_teams/{id}' do
    parameter name: 'id', in: :path, type: :integer
    # Get request on /api/v1/student_teams/{id} returns the response 200 succesful - when correct id passed is present in the database
    get('Show a Student Team') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          expect(response.status).to eq(200)
        end
      end

      # Get request on /api/v1/student_teams/{id} returns the response 404 not found - when correct id passed is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
          run_test! do
            expect(response.status).to eq(404)
          end
      end
    end

    delete('Delete a Student Team') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      # delete request on /api/v1/student_teams/{id} returns 204 succesful response when id present in the database is deleted successfully
      response(204, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: ''
            }
          }
        end
        run_test! do
          expect(response.status).to eq(204)
        end
      end

      # delete request on /api/v1/student_teams/{id} returns 404 not found response, when id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! do
          expect(response.status).to eq(404)
        end
      end
    end
  end

  path '/api/v1/student_teams/{id}/remove_participant' do
    parameter name: 'id', in: :path, type: :integer, description: 'ID of Team'
    parameter name: 'student_id', in: :query, type: :integer, description: 'ID of the Student'

    let(:student) { create(:user, :student) }
    let(:assignment) { create(:assignment) }
    let(:student_participant) { create(:assignment_participant, user: student, assignment: assignment) }
    let(:team) { create(:assignment_team, assignment: assignment) }
    let(:id) { team.id }
    let(:student_id) { student.id }

    before do
      team.add_member(student, assignment.id)
    end

    delete('remove participant') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:Authorization) { "Bearer #{@token}" }

        run_test! do
          expect(response.status).to eq(204)
          expect(team.members).not_to include(student)
        end
      end

      response(404, 'team not found') do
        let(:id) { -1 } # Invalid ID

        run_test! do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['error']).to eq('Team not found.')
        end
      end

      response(404, 'user not found') do
        let(:student_id) { -1 } # Invalid student ID

        run_test! do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['error']).to eq('User not found.')
        end
      end
    end
  end

  path '/api/v1/student_teams/{id}/add_participant' do
    parameter name: 'id', in: :path, type: :integer, description: 'ID of Team'
    parameter name: 'student_id', in: :query, type: :integer, description: 'ID of the Student'

    let(:student) { create(:user, :student) }
    let(:assignment) { create(:assignment) }
    let(:student_participant) { create(:assignment_participant, user: student, assignment: assignment) }
    let(:team) { create(:assignment_team, assignment: assignment) }
    let(:id) { team.id }
    let(:student_id) { student.id }
    
    patch('Add a participant to Student Team') do
      tags 'Student Teams'
      consumes 'application/json'
      produces 'application/json'
      security [Bearer: {}]
      before do
        team.add_member(student, assignment.id)
      end

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! 
      end
    end
  end
end
