require 'swagger_helper'
require 'rails_helper'

RSpec.describe "Quiz Questionnaires", type: :request do

  before do
    Assignment.create(id: 1, name: "QuizAssignmentTest1", require_quiz: true)
    Assignment.create(id: 2, name: "QuizAssignmentTest2", require_quiz: false)
  end

  let(:role_admin) { Role.create(name: 'Administrator', parent_id: nil, default_page_id: nil) }
  let(:role_ta) { Role.create(name: 'Teaching Assistant', parent_id: nil, default_page_id: nil) }

  let(:institution) { Institution.create(name: 'NCSU') }

  let(:user) do
    institution
    role_admin
    User.create(id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: role_admin.id, institution_id: institution.id)
  end

  let(:team) { Team.create(name: "team1") }

  let(:participant) do
    user
    assignment_with_quiz
    team
    Participant.create(user_id: user.id, assignment_id: assignment_with_quiz.id, team_id: team.id)
  end

  let(:quizQuestionnaire1) do
    team
    assignment_with_quiz
    Questionnaire.create(
      name: 'QuizQuestionnaireTest1',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 10,
      instructor_id: team.id,
      assignment_id: assignment_with_quiz.id
    )
  end

  let(:quizQuestionnaire2) do
    team
    assignment_with_quiz
    Questionnaire.create(
      name: 'QuizQuestionnaireTest2',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 99,
      instructor_id: team.id,
      assignment_id: assignment_with_quiz.id
    )
  end

  let(:auth_token) { generate_auth_token(user) }
  let(:headers) {
    {
      'Authorization' => "Bearer #{auth_token}",
      'Content-Type' => 'application/json'
    }
  }

  path '/api/v1/quiz_questionnaires' do

    get 'Get quiz Questionnaires' do
      tags 'QuizQuestionnaires'
      produces 'application/json'

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      response(200, 'successful') do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        run_test! do
          expect(response.body.size).to eq(2)
        end
      end
    end

    post('create Quiz questionnaire') do

      let(:valid_questionnaire_params) do
        {
          assignment_id: 2,
          participant_id: 1,
          team_id: 1,
          user_id: 1,
          questionnaire_type: 'Quiz Questionnaire',
          name: 'TestCreateQuizQ101',
          private: false,
          min_question_score: 0,
          max_question_score: 100
        }
      end

      let(:invalid_questionnaire_params) do
        {
          assignment_id: 1,
          participant_id: 1,
          team_id: 1,
          user_id: 1,
          questionnaire_type: 'Quiz Questionnaire',
          name: nil,
          private: false,
          min_question_score: 0,
          max_question_score: 100
        }
      end

      get 'List quiz questionnaires' do
        tags 'Quiz Questionnaires'
        produces 'application/json'

        tags 'QuizQuestionnaires'
        consumes 'application/json'
        produces 'application/json'

        parameter name: 'quiz_questionnaire', in: :body, schema: {
          type: :object,
          properties: {
            assignment_id: { type: :integer },
            questionnaire_type: { type: :string },
            name: { type: :string },
            private: { type: :boolean },
            min_question_score: { type: :integer },
            max_question_score: { type: :integer }
          },
          required: %w[name questionnaire_type private min_question_score max_question_score assignment_id]
        }

        let('quiz_questionnaire') { valid_questionnaire_params }

        parameter name: 'assignment_id', in: :body, type: :integer
        parameter name: 'participant_id', in: :body, type: :integer
        parameter name: 'team_id', in: :body, type: :integer
        parameter name: 'user_id', in: :body, type: :integer

        parameter name: 'Authorization', in: :header, type: :string
        parameter name: 'Content-Type', in: :header, type: :string

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let('user_id') { valid_questionnaire_params.user_id }
        let('assignment_id') { valid_questionnaire_params[:assignment_id] }
        let('participant_id') { valid_questionnaire_params[:participant_id] }
        let('team_id') { valid_questionnaire_params[:team_id] }


        # post request on /api/v1/questionnaires creates questionnaire with response 201 when correct params are passed
        response(201, 'created') do
          run_test! do
            response_b = JSON.parse(response)
            puts response_b
            expect(response).to have_http_status(:created)

            # expect(response_body['name']).to eq('TestCreateQuizQ101')
          end
        end

        # post request on /api/v1/questionnaires returns 422 response - unprocessable entity when wrong params is passed toc reate questionnaire
        response(422, 'unprocessable entity') do
          let('Authorization') { "Bearer #{auth_token}" }
          let('Content-Type') { 'application/json' }

          let('user_id') { valid_questionnaire_params.user_id }
          let('assignment_id') { valid_questionnaire_params[:assignment_id] }
          let('participant_id') { valid_questionnaire_params[:participant_id] }
          let('team_id') { valid_questionnaire_params[:team_id] }

          run_test!
        end

      end

    end
  end

  # path '/api/v1/quiz_questionnaires/{id}' do
  #   parameter name: :id, in: :path, type: :string
  #
  #   get 'Retrieve a quiz questionnaire' do
  #     tags 'Quiz Questionnaires'
  #     produces 'application/json'
  #
  #     response '200', 'Quiz questionnaire details' do
  #       run_test! do
  #         # Provide the test scenario to retrieve a quiz questionnaire by ID
  #         # Example data:
  #         let(:id) { '1' }
  #       end
  #     end
  #
  #     response '404', 'Not Found' do
  #       run_test! do
  #         # Provide a scenario that triggers a 404 response
  #         # Example data:
  #         let(:id) { '999' } # An ID that does not exist
  #       end
  #     end
  #   end
  #
  #   put 'Update a quiz questionnaire' do
  #     tags 'Quiz Questionnaires'
  #     consumes 'application/json'
  #     parameter name: :quiz_questionnaire, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         # Define the properties for updating a quiz questionnaire
  #         name: { type: :string },
  #         questionnaire_type: { type: :string },
  #         private: { type: :boolean },
  #         min_question_score: { type: :integer },
  #         max_question_score: { type: :integer },
  #         instructor_id: { type: :integer },
  #         assignment_id: { type: :integer }
  #       },
  #       required: ['name', 'questionnaire_type', 'private', 'min_question_score', 'max_question_score', 'instructor_id', 'assignment_id']
  #     }
  #
  #     response '200', 'Quiz questionnaire updated' do
  #       run_test! do
  #         # Provide the request body data to update a quiz questionnaire
  #         # Example data:
  #         let(:quiz_questionnaire) do
  #           {
  #             name: 'Updated Quiz',
  #             questionnaire_type: 'Quiz Questionnaire',
  #             private: true,
  #             min_question_score: 5,
  #             max_question_score: 50,
  #             instructor_id: 1,
  #             assignment_id: 1
  #           }
  #         end
  #       end
  #     end
  #
  #     response '422', 'Unprocessable Entity' do
  #       run_test! do
  #         # Provide invalid or incomplete data to trigger a 422 response
  #         let(:quiz_questionnaire) do
  #           {
  #             name: '', # Invalid: Name is required
  #             questionnaire_type: '', # Invalid: Type is required
  #             private: nil, # Invalid: Private should be a boolean
  #             min_question_score: -1, # Invalid: Min score should be non-negative
  #             max_question_score: 10, # Invalid: Max score should be less than min score
  #             instructor_id: 'invalid_id', # Invalid: Instructor ID should be an integer
  #             assignment_id: nil # Invalid: Assignment ID is required
  #           }
  #         end
  #       end
  #     end
  #   end
  #
  #   delete 'Delete a quiz questionnaire' do
  #     tags 'Quiz Questionnaires'
  #
  #     response '200', 'Quiz questionnaire deleted' do
  #       run_test! do
  #         # Provide the scenario to delete a quiz questionnaire
  #         # Example data:
  #         let(:id) { '1' } # ID of the quiz questionnaire to be deleted
  #       end
  #     end
  #
  #     response '404', 'Not Found' do
  #       run_test! do
  #         # Provide a scenario that triggers a 404 response
  #         # Example data:
  #         let(:id) { '999' } # An ID that does not exist
  #       end
  #     end
  #   end

end


