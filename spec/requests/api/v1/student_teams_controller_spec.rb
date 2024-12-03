require 'swagger_helper'

RSpec.describe 'Student Teams API', type: :request do
  path '/api/v1/student_teams' do
    # List all Student Teams
    get('List all Student Teams') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'List Student Teams') do
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

  path '/api/v1/student_teams/{id}' do
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

    # Get request on /api/v1/student_teams/{id} returns the response 200 succesful - bookmark with id = {id} when correct id is passed which is in the database
    get('show Studen Team') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      response(200, 'successful') do
        run_test! 
        # do
          # expect(response.body).to include('"title":"Example Bookmark"')
        # end
      end

      # Get request on /api/v1/student_teams/{id} returns the response 404 not found - bookmark with id = {id} when correct id is passed which is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
          run_test! 
          # do
            # expect(response.body).to include("Couldn't find Bookmark")
          # end
      end
    end

    # put('update bookmark') do
    #   tags 'Student Teams'
    #   consumes 'application/json'
    #   produces 'application/json'

    #   parameter name: :body_params, in: :body, schema: {
    #     type: :object,
    #     properties: {
    #       title: { type: :string }
    #     }
    #   }

    #   # put request on /api/v1/student_teams/{id} returns 200 response succesful when bookmark id is present in the database and correct valid params are passed
    #   response(200, 'successful') do
    #     let(:body_params) do
    #       {
    #         title: 'Updated Bookmark Title'
    #       }
    #     end
    #     run_test! do
    #       expect(response.body).to include('"title":"Updated Bookmark Title"')
    #     end
    #   end

    #   # put request on /api/v1/student_teams/{id} returns 404 not found when id is not present in the database which bookmark needs to be updated
    #   response(404, 'not found') do
    #     let(:id) { 0 }
    #     let(:body_params) do
    #       {
    #         title: 'Updated Bookmark Title'
    #       }
    #     end
    #     run_test! do
    #       expect(response.body).to include("Couldn't find Bookmark")
    #     end
    #   end

    #   # put request on /api/v1/student_teams/{id} returns 422 response unprocessable entity when correct parameters for the bookmark to be updated are not passed
    #   response(422, 'unprocessable entity') do
    #     let(:body_params) do
    #       {
    #         title: nil
    #       }
    #     end
    #     schema type: :string
    #     run_test! do
    #       expect(response.body).to_not include('"title":null')
    #     end
    #   end
    # end

    delete('delete Student Team') do
      tags 'Student Teams'
      produces 'application/json'
      security [Bearer: {}]

      # delete request on /api/v1/student_teams/{id} returns 204 succesful response when bookmark with id present in the database is succesfully deleted
      response(204, 'successful') do
        run_test! 
        # do
          # expect(Bookmark.exists?(id)).to eq(false)
        # end
      end

      # delete request on /api/v1/student_teams/{id} returns 404 not found response when bookmark id is not present in the database
      response(404, 'not found') do
        let(:id) { 0 }
        run_test! 
        # do
          # expect(response.body).to include("Couldn't find Bookmark")
        # end
      end
    end
  end

end


RSpec.describe 'Student Teams', type: :request do
  path '/api/v1/student_teams' do
    post 'create Student Team' do
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

      # In your test or controller
      
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
          expect(response.body).to include('"name":"ABCD10"')
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
    end

    patch('Update Student Team') do
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

      response(200, 'Update Student Teams') do
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
