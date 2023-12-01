require 'swagger_helper'
require 'rails_helper'

RSpec.describe "api/v1/questionnaires", type: :request do

  before do
    Role.create(id: 1, name: 'Teaching Assistant', parent_id: nil, default_page_id: nil)
    Role.create(id: 2, name: 'Administrator', parent_id: nil, default_page_id: nil)

    # Team.create(id: 1, name: "team1")
    #
    Institution.create(id: 2, name: 'Not_NCSU')
    User.create(id: 2, name: "nopermission", full_name: "nopermission", email: "nopermission@gmail.com", password_digest: "nopermission", role_id: 1, institution_id: 2)


    Assignment.create(id: 1, name: "QuizAssignmentTest1", require_quiz: true)
    Assignment.create(id: 2, name: "QuizAssignmentTest2", require_quiz: false)

    Participant.create(id: 1, user_id: user.id, assignment_id: 1, team_id: team.id)
  end

  let(:institution) { Institution.create(id: 1, name: 'NCSU') }

  let(:user) do
    institution
    User.create(id: 1, name: "admin", full_name: "admin", email: "admin@gmail.com", password_digest: "admin", role_id: 2, institution_id: institution.id)
  end

  # let(:user_no_permission) do
  #   institution
  #   User.create(id: 2, name: "nopermission", full_name: "nopermission", email: "nopermission@gmail.com", password_digest: "nopermission", role_id: 1, institution_id: institution.id)
  # end

  let(:team) { Team.create(id: 1, name: "team1") }

  let(:quizQuestionnaire1) do
    team
    Questionnaire.create(
      id: 3,
      name: 'QuizQuestionnaireTest1',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 10,
      instructor_id: team.id,
      assignment_id: 1
    )
  end

  let(:quizQuestionnaire2) do
    team
    Questionnaire.create(
      id: 2,
      name: 'QuizQuestionnaireTest2',
      questionnaire_type: 'Quiz Questionnaire',
      private: true,
      min_question_score: 0,
      max_question_score: 99,
      instructor_id: team.id,
      assignment_id: 1
    )
  end

  let(:auth_token) { generate_auth_token(user) }

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

    post 'create Quiz questionnaire' do
      tags 'QuizQuestionnaires'
      consumes 'application/json'
      produces 'application/json'


      parameter name: 'quiz_questionnaire', in: :body, schema: {
        type: :object,
        properties: {
          assignment_id: { type: :integer },
          participant_id: { type: :integer },
          team_id: { type: :integer },
          user_id: { type: :integer },
          questionnaire_type: { type: :string },
          name: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer }
        }
      }

      let(:valid_questionnaire_params) do
        {
          assignment_id: 1,
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
          name: "InvalidQuizQuestionnaire",
          private: false,
          min_question_score: 100,
          max_question_score: 0
        }
      end

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      let('Authorization') { "Bearer #{auth_token}" }
      let('Content-Type') { 'application/json' }

      # post request on /api/v1/questionnaires creates questionnaire with response 201 when correct params are passed
      response(201, 'created') do

        let('quiz_questionnaire') { valid_questionnaire_params }

        run_test! do
          expect(response).to have_http_status(:created)
          expect(response.body).to include('TestCreateQuizQ101')
        end
      end

      # post request on /api/v1/questionnaires returns 422 response - unprocessable entity when wrong params is passed toc reate questionnaire
      response(422, 'unprocessable entity') do
        let('quiz_questionnaire') { invalid_questionnaire_params }
        run_test!
      end

    end
  end

  path '/api/v1/quiz_questionnaires/copy/{id}' do

    post 'Copy a quiz Questionnaire' do
      tags 'Quiz Questionnaires'

      parameter name: :id, in: :path, type: :string

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      before do

          Questionnaire.create(
            id: 69,
            name: 'QuestionnaireToBeCopied',
            questionnaire_type: 'Quiz Questionnaire',
            private: true,
            min_question_score: 1,
            max_question_score: 70,
            instructor_id: 1,
            assignment_id: 1
          )

      end

      response '200', 'Quiz questionnaire copied' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) {'69'}
        run_test!
      end

      response '404', 'Not Found' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) { '999' }
        run_test!
      end

    end

  end

  path '/api/v1/quiz_questionnaires/{id}' do

    get 'Retrieve a quiz questionnaire' do
      tags 'Quiz Questionnaires'
      produces 'application/json'

      parameter name: :id, in: :path, type: :string

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      before do
        Questionnaire.create(
          id: 1,
          name: 'QuizQuestionnaireTest1',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 10,
          instructor_id: 1,
          assignment_id: 1
        )
      end

      response '200', 'Quiz questionnaire details' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let('id') { 1 }

        run_test!
      end

      response '404', 'Not Found' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) { '999' }
        run_test!
      end
    end

    put 'Update a quiz questionnaire' do

      tags 'Quiz Questionnaires'
      consumes 'application/json'

      parameter name: :id, in: :path, type: :string

      parameter name: :questionnaire_params, in: :body, schema: {
        type: :object,
        properties: {
          user_id: {type: :integer},
          name: { type: :string },
          private: { type: :boolean },
          min_question_score: { type: :integer },
          max_question_score: { type: :integer },
          instructor_id: { type: :integer },
          assignment_id: { type: :integer }
        },
        required: ['user_id']
      }

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      before do
        Questionnaire.create(
          id: 1,
          name: 'QuizQuestionnaireTest1',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 0,
          max_question_score: 10,
          instructor_id: 1,
          assignment_id: 1
        )
      end


      response '200', 'Quiz questionnaire updated' do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let(:questionnaire_params) do
          {
            user_id: 1,
            name: 'Updated Quiz',
            private: true,
            min_question_score: 5,
            max_question_score: 50
          }
        end

        let('id'){1}

        run_test!

      end

      response '422', 'Unprocessable Entity' do

        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let(:questionnaire_params) do
          {
            user_id: 1,
            min_question_score: -1, # Invalid: Min score should be non-negative
            max_question_score: 10, # Invalid: Max score should be less than min score
            instructor_id: 'invalid_id', # Invalid: Instructor ID should be an integer
            assignment_id: nil # Invalid: Assignment ID is required
          }
        end

        let('id'){1}
        run_test!
      end

      response '422', 'Unprocessable Entity: Require Permission to Update' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }

        let(:questionnaire_params) do
          {
            user_id: 2,
            name: 'Updated Quiz',
            private: true,
            min_question_score: 4,
            max_question_score: 40
          }
        end

        let('id'){1}

        run_test!
      end
    end

    delete 'Delete a quiz questionnaire' do
      tags 'Quiz Questionnaires'

      parameter name: :id, in: :path, type: :string

      parameter name: 'Authorization', in: :header, type: :string
      parameter name: 'Content-Type', in: :header, type: :string

      parameter name: 'quiz_questionnaire', in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer }
        }
      }

      before do

        Questionnaire.create(
          id: 123,
          name: 'QuestionnaireToBeCopied',
          questionnaire_type: 'Quiz Questionnaire',
          private: true,
          min_question_score: 1,
          max_question_score: 70,
          instructor_id: 1,
          assignment_id: 1
        )

      end

      response '204', 'Quiz questionnaire deleted' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) {'123'}
        let('quiz_questionnaire') {{user_id: 1}}

        run_test!
      end

      response '404', 'Not Found' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) { '999' }
        let('quiz_questionnaire') {{user_id: 1}}
        run_test!
      end

      response '422', 'unprocessable_entity: Require Permission to Delete' do
        let('Authorization') { "Bearer #{auth_token}" }
        let('Content-Type') { 'application/json' }
        let(:id) { '123' }
        let('quiz_questionnaire') {{user_id: 2}}
        run_test!
      end


    end

  end


end


